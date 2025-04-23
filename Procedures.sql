-- 1. Trains from a particular station

DELIMITER //
CREATE PROCEDURE GetTrainsBetweenStations(
    IN source_station_name VARCHAR(100),
    IN dest_station_name VARCHAR(100),
    IN journey_date DATE
)
BEGIN
    DECLARE source_id INT;
    DECLARE dest_id INT;

    -- Get Station IDs
    SELECT StationID INTO source_id FROM Stations WHERE StationName = source_station_name;
    SELECT StationID INTO dest_id FROM Stations WHERE StationName = dest_station_name;

    -- Check if stations exist
    IF source_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source station not found';
    END IF;
    IF dest_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destination station not found';
    END IF;

    -- Main query to find available trains
    SELECT 
        t.TrainID,
        t.TrainNumber,
        t.TrainName,
        t.TrainType,
        origin_sch.DepartureTime AS OriginDepartureTime,
        s1.DepartureTime AS SourceDepartureTime,
        s2.ArrivalTime AS DestinationArrivalTime,
        (s2.DistanceFromOrigin - s1.DistanceFromOrigin) AS Distance
    FROM Trains t
    INNER JOIN Schedules s1 
        ON t.TrainID = s1.TrainID 
        AND s1.StationID = source_id
    INNER JOIN Schedules s2 
        ON t.TrainID = s2.TrainID 
        AND s2.StationID = dest_id 
        AND s2.StationSerialNo > s1.StationSerialNo
    INNER JOIN Schedules origin_sch 
        ON t.TrainID = origin_sch.TrainID 
        AND origin_sch.StationSerialNo = 1
    INNER JOIN Stations src_st 
        ON s1.StationID = src_st.StationID
    INNER JOIN Stations dest_st 
        ON s2.StationID = dest_st.StationID
    WHERE 
        -- Check if the train runs on the calculated origin departure day
        CASE 
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 2 THEN origin_sch.IsOnMonday
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 3 THEN origin_sch.IsOnTuesday
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 4 THEN origin_sch.IsOnWednesday
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 5 THEN origin_sch.IsOnThursday
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 6 THEN origin_sch.IsOnFriday
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 7 THEN origin_sch.IsOnSaturday
            WHEN DAYOFWEEK(journey_date - INTERVAL (s1.DayNumber - 1) DAY) = 1 THEN origin_sch.IsOnSunday
        END = TRUE
        AND t.IsActive = TRUE
    ORDER BY s1.DepartureTime;
END //
DELIMITER ;

drop procedure GetTrainsBetweenStations;
CALL GetTrainsBetweenStations('Nagpur Junction', 'Pune Junction', '2025-05-25');


-- 2. Function for Fare Calulation
DELIMITER $$
CREATE FUNCTION CalculateTicketFare(
    train_id INT, 
    class VARCHAR(20), 
    passenger_id INT
) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE base_fare DECIMAL(10,2);
    DECLARE concession DECIMAL(5,2) DEFAULT 0;
    DECLARE distance INT;
    DECLARE temp Decimal(5, 2) DEFAULT 0;
    
    SELECT TotalDistance INTO distance FROM Trains WHERE TrainID = train_id;
    SELECT FarePerKilometer INTO base_fare FROM Classes WHERE ClassName = class;
    
    SELECT MAX(c.ConcessionPercentage) INTO temp
    FROM Passengers p
    LEFT JOIN Concessions c ON 
        (p.Age >= 60 AND c.Category = 'Senior Citizen') OR
        (p.Disability = TRUE AND c.Category = 'Disability') OR
        (p.Age BETWEEN 18 AND 25 AND c.Category = 'Student')
    WHERE p.PassengerID = passenger_id;
    
    if temp is not null then 
		set concession = temp;
	end if;
    
    RETURN (distance * base_fare) * (1 - (concession/100));
END$$
DELIMITER ;

select CalculateTicketFare(3, '2AC', 1); 

 -- 3. Generate PNR Number
 
DELIMITER $$
CREATE FUNCTION GeneratePNR(
    source_id int, 
    dest_id int, 
    journey_date DATE
) 
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
	Declare source_code varchar(20);
    Declare dest_code varchar(20);
    
    select StationCode into source_code from stations where StationID = source_id;
    select StationCode into dest_code from stations where StationID = dest_id;
    RETURN CONCAT(
        LEFT(source_code, 2),
        LEFT(dest_code, 2),
        DATE_FORMAT(journey_date, '%d%m'),
        FLOOR(RAND() * 90 + 10)
    );
END$$
DELIMITER ;

select GeneratePNR(7, 11, '2025-04-18');

-- 4. Booking Procedure

DELIMITER $$
CREATE PROCEDURE BookTicket(
    IN p_passenger_id INT,
    IN p_train_id INT,
    IN p_class VARCHAR(20),
    IN p_journey_date DATE,
    IN p_payment_mode VARCHAR(20)
)
BEGIN
    DECLARE v_seat_id INT;
    DECLARE v_pnr VARCHAR(10);
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_source_id INT;
    DECLARE v_dest_id INT;
    DECLARE sch_id INT;
    DECLARE total_amount DECIMAL(10,2);
    DECLARE concession DECIMAL(5,2) DEFAULT 0;
    DECLARE temp DECIMAL(5,2) DEFAULT 0;
    DECLARE seatnumber VARCHAR(10);
    DECLARE coachnumber VARCHAR(10);
    DECLARE v_ticket_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Get station codes (fixed variable types to INT)
    SELECT t.OriginStationID, t.DestinationStationID INTO v_source_id, v_dest_id
    FROM Trains t
    WHERE t.TrainID = p_train_id;

    -- Get schedule id
    SELECT ScheduleId INTO sch_id
    FROM Schedules
    WHERE StationID = v_source_id AND TrainID = p_train_id;

    -- Calculate concession amount
    SELECT MAX(c.ConcessionPercentage) INTO temp
    FROM Passengers p
    LEFT JOIN Concessions c ON 
        (p.Age >= 60 AND c.Category = 'Senior Citizen') OR
        (p.Disability = TRUE AND c.Category = 'Disability') OR
        (p.Age BETWEEN 18 AND 25 AND c.Category = 'Student')
    WHERE p.PassengerID = p_passenger_id;

    IF temp IS NOT NULL THEN 
        SET concession = temp;
    END IF;

    -- Find available seat
    SELECT SeatID INTO v_seat_id
    FROM Seats 
    WHERE TrainID = p_train_id
      AND Class = p_class
      AND IsBooked = FALSE
    LIMIT 1 FOR UPDATE;

    IF v_seat_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No seats available in requested class';
    END IF;

    -- Calculate fare
    SET v_fare = CalculateTicketFare(p_train_id, p_class, p_passenger_id);
    SET total_amount = (100 * v_fare) / (100 - concession);

    -- Generate PNR
    SET v_pnr = GeneratePNR(v_source_id, v_dest_id, p_journey_date);

    -- Get Seat and Coach No
    SELECT SeatNo, CoachNo INTO seatnumber, coachnumber
    FROM Seats
    WHERE SeatID = v_seat_id;

    -- Create ticket and get the auto-generated ID
    INSERT INTO Tickets 
        (PNRNo, PassengerID, TrainID, Class, JourneyDate, BookingDateTime, Status, 
         SeatNo, CoachNo, SourceStationID, DestinationStationID, ScheduleID, Fare, ConcessionAmount)
    VALUES 
        (v_pnr, p_passenger_id, p_train_id, p_class, p_journey_date, NOW(), 'Confirmed', 
         seatnumber, coachnumber, v_source_id, v_dest_id, sch_id, v_fare, (total_amount - v_fare));
    
    SET v_ticket_id = LAST_INSERT_ID();

    -- Update seat
    UPDATE Seats SET IsBooked = TRUE WHERE SeatID = v_seat_id;

    -- Process payment with the correct TicketID
    INSERT INTO Payments 
        (TicketID, Amount, PaymentMode, PaymentStatus, TransactionID, TransactionDateTime) 
    VALUES 
        (v_ticket_id, v_fare, p_payment_mode, 'Completed', 
         CONCAT('TXN', FLOOR(RAND() * 1000000)), NOW());

    COMMIT;
END$$
DELIMITER ;

drop procedure BookTicket;
INSERT INTO Seats (TrainID, CoachNo, SeatNo, Class, IsRAC, isBooked, JourneyDate) values (41, 'B1', 10, '2AC', False, False, '2025-04-25');
call BookTicket(1, 41, '2AC', '2025-04-25', 'Credit Card');

-- 5. Automatic Seat Release on Cancellation

DELIMITER $$
CREATE TRIGGER AfterCancellation
AFTER INSERT ON Cancellations
FOR EACH ROW
BEGIN
    UPDATE Seats s
    JOIN Tickets t ON s.TrainID = t.TrainID 
      AND s.SeatNo = t.SeatNo 
      AND s.CoachNo = t.CoachNo
    SET s.IsBooked = FALSE
    WHERE t.TicketID = NEW.TicketID;
    
END$$
DELIMITER ;

-- 6. Procedure for cancellating a train

Delimiter $$
create procedure cancelTicket(in p_TicketID int, in reason varchar(255))
begin
	declare refund_amount DECIMAL(10,2);
	select Fare*0.1 into refund_amount from Tickets where TicketID = p_TicketID;
	insert into cancellations (TicketID, CancellationDateTime, RefundAmount, RefundStatus, CancellationReason) values (p_TicketID, now(), refund_amount, 'Processed', reason);
	update Tickets set Status = 'Cancelled' where TicketID = p_TicketId;
end $$
Delimiter ;

drop procedure cancelTicket;
call cancelTicket(77, 'Plan change');

-- 7. Schedule Management

DELIMITER $$
CREATE PROCEDURE UpdateSchedule(
    IN p_train_id INT,
    IN p_station_id INT,
    IN p_arrival TIME,
    IN p_departure TIME
)
BEGIN
   
   Declare curr_arrival_time time;
   Declare curr_dept_time time;
   
   select ArrivalTime, DepartureTime into curr_arrival_time, curr_dept_time from Schedules where TrainID = p_train_id and StationID = p_station_id;
   IF (curr_arrival_time IS NULL and p_arrival is not NULL) or (curr_dept_time IS NULL and p_departure is not NULL) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This is Starting Station. So, Arrival Time cant be scheduled';
    END IF;
    
    
    UPDATE Schedules 
    SET ArrivalTime = p_arrival,
        DepartureTime = p_departure
    WHERE TrainID = p_train_id
      AND StationID = p_station_id;
END$$
DELIMITER ;

call UpdateSchedule(1, 2, NULL, '06:10:00');

-- 8. Daily Payment Reconciliation

DELIMITER $$
CREATE PROCEDURE ReconcilePayments()
BEGIN
    UPDATE Payments p
    JOIN Tickets t ON p.TicketID = t.TicketID
    SET p.PaymentStatus = 'Failed'
    WHERE p.PaymentStatus = 'Pending'
      AND TIMESTAMPDIFF(HOUR, p.TransactionDateTime, NOW()) > 24;
    
    UPDATE Tickets t
    JOIN Payments p ON t.TicketID = p.TicketID
    SET t.Status = 'Cancelled'
    WHERE p.PaymentStatus = 'Failed'
      AND t.Status = 'Confirmed';
END$$
DELIMITER ;

call ReconcilePayments();

-- 9. Automatic Waitlist Promotion
DELIMITER $$
CREATE EVENT PromoteWaitlist
ON SCHEDULE EVERY 15 MINUTE
DO
BEGIN
    -- Promote RAC to confirmed
    UPDATE Tickets
    SET Status = 'Confirmed'
    WHERE Status = 'RAC'
      AND EXISTS (
          SELECT 1 FROM Seats 
          WHERE TrainID = Tickets.TrainID
            AND Class = Tickets.Class
            AND IsAvailable = TRUE
      );
    
    -- Promote WL to RAC
    UPDATE Tickets t1
    JOIN (
        SELECT TicketID 
        FROM Tickets 
        WHERE Status = 'WL'
        ORDER BY BookingDateTime
        LIMIT 5
    ) t2 ON t1.TicketID = t2.TicketID
    SET t1.Status = 'RAC';
END$$
DELIMITER ;

-- 10. Validate Schedule Updates
DELIMITER $$  
CREATE TRIGGER BeforeScheduleUpdate  
BEFORE UPDATE ON Schedules  
FOR EACH ROW  
BEGIN  
    IF NEW.DepartureTime < NEW.ArrivalTime THEN  
        SIGNAL SQLSTATE '45000'  
        SET MESSAGE_TEXT = 'Departure time cannot be before arrival time';  
    END IF;  
END$$  
DELIMITER ;

update Schedules set DepartureTime = '10:05:00' where ScheduleID = 2;

 -- 11. Occupancy Report
 
DELIMITER $$  
CREATE PROCEDURE GenerateOccupancyReport(IN train_id INT, IN journey_date DATE)  
BEGIN  
    SELECT 
        Class,
        COUNT(*) AS TotalSeats,
        SUM(CASE WHEN Status = 'Confirmed' THEN 1 ELSE 0 END) AS Confirmed,
        SUM(CASE WHEN Status = 'RAC' THEN 1 ELSE 0 END) AS RAC,
        SUM(CASE WHEN Status = 'WL' THEN 1 ELSE 0 END) AS WL,
        SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled
    FROM Tickets
    WHERE TrainID = train_id AND JourneyDate = journey_date
    GROUP BY Class;
END$$  
DELIMITER ;

call GenerateOccupancyReport(41, '2025-04-16');

-- 12. Notify on Ticket Confirmation

DELIMITER $$  
CREATE TRIGGER AfterTicketStatusUpdate  
AFTER UPDATE ON Tickets  
FOR EACH ROW  
BEGIN  
    IF NEW.Status = 'Confirmed' AND OLD.Status IN ('RAC', 'WL') THEN  
        INSERT INTO Notifications (PassengerID, Message, CreatedAt, TicketID)
        VALUES (NEW.PassengerID, CONCAT('Your ticket ', NEW.PNRNo, ' has been confirmed!'), NOW(), NEW.TicketID);
    END IF;  
END$$  
DELIMITER ;

update Tickets set Status = 'Confirmed' where TicketID = 3;






