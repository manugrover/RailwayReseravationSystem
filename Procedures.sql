
-- 1. Function for Fare Calulation
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

 -- 2. Generate PNR Number
 
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

-- 3. Booking Procedure

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
      AND IsBooked = TRUE
      AND (IsRAC = FALSE OR p_class = 'Sleeper')
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
    UPDATE Seats SET IsBooked = FALSE WHERE SeatID = v_seat_id;

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
call BookTicket(1, 41, '1AC', '2025-04-14', 'Credit Card');

-- 4. Automatic Seat Release on Cancellation

DELIMITER $$
CREATE TRIGGER AfterCancellation
AFTER INSERT ON Cancellations
FOR EACH ROW
BEGIN
    UPDATE Seats s
    JOIN Tickets t ON s.TrainID = t.TrainID 
      AND s.SeatNo = t.SeatNo 
      AND s.CoachNo = t.CoachNo
    SET s.IsAvailable = TRUE
    WHERE t.TicketID = NEW.TicketID;
END$$
DELIMITER ;

-- 5. Schedule Management

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

drop Procedure UpdateSchedule;
call UpdateSchedule(1, 2, NULL, '06:05:00');

-- 6. Daily Payment Reconciliation

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

-- 7. Automatic Waitlist Promotion
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

-- 8. Validate Schedule Updates
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
DELIMITER 

 -- 9. Occupancy Report
 
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

-- 10. Notify on Ticket Confirmation

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





