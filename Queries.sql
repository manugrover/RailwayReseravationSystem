select * from Seats;
select * from passengers;
select * from concessions;
select * from Cancellations;
select * from Tickets;
select * from Trains;
select * from schedules;
select * from stations;
select * from payments;
select * from Notifications;
select * from Classes;
select * from Payments;

-- 1. PNR Status Tracking for a Given Ticket
SELECT t.PNRNo, t.Status, t.JourneyDate, 
       tr.TrainNumber, tr.TrainName,
       s_src.StationCode AS SourceStation,
       s_dest.StationCode AS DestStation,
       p.FirstName, p.LastName, t.SeatNo, t.CoachNo
FROM Tickets t
JOIN Trains tr ON t.TrainID = tr.TrainID
JOIN Stations s_src ON t.SourceStationID = s_src.StationID
JOIN Stations s_dest ON t.DestinationStationID = s_dest.StationID
JOIN Passengers p ON t.PassengerID = p.PassengerID
WHERE t.PNRNo = 'PNR1003'; 

-- 2. Train Schedule Lookup for a Given Train
SELECT sch.StationSerialNo, s.StationCode,s.StationName, 
       sch.ArrivalTime, sch.DepartureTime,
       sch.DistanceFromOrigin, sch.DayNumber
FROM Schedules sch
JOIN Stations s ON sch.StationID = s.StationID
WHERE sch.TrainID = (SELECT TrainID FROM Trains WHERE TrainNumber = '12001')
ORDER BY sch.StationSerialNo;

-- 3. Available Seats for Specific Train, Date and Class
Delimiter $$
create Procedure CheckSeatAvailability(in class varchar(10), in p_TrainNumber varchar(10), in p_JourneyDate date)
begin
	SELECT 
    s.SeatID,
    s.CoachNo,
    s.SeatNo
FROM 
    Seats s
    where s.TrainID != (select TrainID from Trains where TrainNumber = p_TrainNumber)
    and JourneyDate = p_JourneyDate
	and Class = class
    and isBooked is False;
end $$
Delimiter ;

call CheckSeatAvailability('3AC', '12951', '2025-04-10');
  
-- 4. Passengers on Specific Train + Date
SELECT DISTINCT p.PassengerID, p.FirstName, p.LastName, t.SeatNo, t.CoachNo, t.Class
FROM Tickets t
JOIN Passengers p ON t.PassengerID = p.PassengerID
WHERE t.TrainID = (SELECT TrainID FROM Trains WHERE TrainNumber = '12951')
  AND t.JourneyDate = '2024-03-25'
  AND t.Status != 'Cancelled';
  
-- 5. Waitlisted Passengers for a Train

SELECT t.PNRNo, p.FirstName, p.LastName, t.BookingDateTime
FROM Tickets t
JOIN Passengers p ON t.PassengerID = p.PassengerID
WHERE t.TrainID = (SELECT TrainID FROM Trains WHERE TrainNumber = '12951')
  AND t.Status = 'WL'
  AND t.JourneyDate >= CURDATE();
  
  -- 6. Total Refund Amount for Cancelling a Train
  
SELECT SUM(t.Fare) AS TotalRefundAmount
FROM Tickets t
WHERE t.TrainID = (SELECT TrainID FROM Trains WHERE TrainNumber = '12951')
  AND t.JourneyDate > CURDATE()
  AND t.Status != 'Cancelled';
  
-- 7. Total Revenue Over Period

SELECT SUM(p.Amount) AS TotalRevenue
FROM Payments p
JOIN Tickets t ON p.TicketID = t.TicketID
WHERE p.PaymentStatus = 'Completed'
  AND t.BookingDateTime BETWEEN '2025-04-01' AND '2025-04-30';
  
  -- 8. Cancellation Records with Refund Status

SELECT c.CancellationDateTime, c.RefundAmount, c.RefundStatus,
       t.PNRNo, tr.TrainNumber, p.FirstName, p.LastName
FROM Cancellations c
JOIN Tickets t ON c.TicketID = t.TicketID
JOIN Trains tr ON t.TrainID = tr.TrainID
JOIN Passengers p ON t.PassengerID = p.PassengerID
WHERE Date(c.CancellationDateTime) BETWEEN '2025-04-01' AND '2025-04-31';

select * from Cancellations c where Date(c.CancellationDateTime) BETWEEN '2025-04-01' AND '2025-04-30';

-- 9. Busiest Route by Passenger Count

SELECT s1.StationCode AS Source,s1.City as City, s2.StationCode AS Destination,
       COUNT(*) AS PassengerCount
FROM Tickets t
JOIN Stations s1 ON t.SourceStationID = s1.StationID
JOIN Stations s2 ON t.DestinationStationID = s2.StationID
GROUP BY Source, Destination, City
ORDER BY PassengerCount DESC
LIMIT 1;
 
 -- 10. Itemized Bill for a Ticket
 
SELECT t.PNRNo, tr.TrainNumber, t.Class,
       t.Fare AS BaseFare,
       t.ConcessionAmount,
       (t.Fare - t.ConcessionAmount) AS NetFare,
       p.PaymentMode, p.TransactionID,
       COALESCE(c.RefundAmount, 0) AS RefundAmount
FROM Tickets t
JOIN Trains tr ON t.TrainID = tr.TrainID
LEFT JOIN Payments p ON t.TicketID = p.TicketID
LEFT JOIN Cancellations c ON t.TicketID = c.TicketID
WHERE t.PNRNo = 'PNR2005';

-- 11. Average Fare Collection per Kilometer by Class

SELECT c.ClassName, 
       AVG(t.Fare/(tr.TotalDistance/1000)) AS avg_fare_per_km
FROM Tickets t
JOIN Trains tr ON t.TrainID = tr.TrainID
JOIN Classes c ON t.Class = c.ClassName
GROUP BY c.ClassName;


-- 12. Seat Utilization Percentage per Train

select t.TrainNumber, sum(isBooked) as occupied_seats, 
	    count(seatID) as total_seats, Concat((sum(isBooked)/count(seatID))*100, "%") as Utilization 
        from Seats s, Trains t where t.TrainID = s.TrainID group by s.TrainID;
        
-- 13. Disabled Passenger Accommodation

SELECT t.TrainNumber, 
       COUNT(*) AS disabled_passengers
FROM Tickets tic
JOIN Passengers p ON tic.PassengerID = p.PassengerID
JOIN Trains t ON tic.TrainID = t.TrainID
WHERE p.Disability = TRUE
GROUP BY t.TrainNumber
ORDER BY disabled_passengers DESC;

-- 14. Monthly Cancellation Trends

SELECT ELT(MONTH(CancellationDateTime), 'Jan', 'Feb','Mar', 'April','May','June','July','Aug','Sep','Oct','Nov','Dec') AS month,
       COUNT(*) AS cancellations,
       SUM(RefundAmount) AS total_refunds
FROM Cancellations
GROUP BY month
ORDER BY month;
-- 15. Payment Method Distribution

SELECT PaymentMode,
       COUNT(*) AS transactions,
       (COUNT(*)/(SELECT COUNT(*) FROM Payments))*100 AS percentage
FROM Payments
GROUP BY PaymentMode;

-- 16. Passenger Age Demographics

SELECT CASE
         WHEN Age BETWEEN 0 and 12 THEN 'Child'
         WHEN Age BETWEEN 13 and 19 THEN 'Teen'
         WHEN Age BETWEEN 20 and 60 THEN 'Adult'
         ELSE 'Senior'
       END AS age_group,
       COUNT(*) AS passengers
FROM Passengers
GROUP BY age_group;

-- 17. Route Popularity by Bookings

SELECT s1.City as OriginCity, s1.StationCode AS origin,
        s2.City as DestinationCity, s2.StationCode AS destination,
       COUNT(*) AS bookings
FROM Tickets t
JOIN Stations s1 ON t.SourceStationID = s1.StationID
JOIN Stations s2 ON t.DestinationStationID = s2.StationID
GROUP BY origin, destination, OriginCity, DestinationCity
ORDER BY bookings DESC
LIMIT 5;

-- 18.  Frequent Travellers

SELECT p.PassengerID, 
       CONCAT(p.FirstName, ' ', p.LastName) AS name,
       COUNT(*) AS journeys
FROM Tickets t
JOIN Passengers p ON t.PassengerID = p.PassengerID
GROUP BY p.PassengerID
HAVING journeys > 0
ORDER BY journeys DESC;

-- 19.  Ticket Confirmation Probability

SELECT Class,
       (SUM(CASE WHEN Status = 'Confirmed' THEN 1 ELSE 0 END)/COUNT(*))*100 AS confirmation_rate
FROM Tickets
GROUP BY Class;

-- 20. Station Connectivity Index

SELECT s.StationCode, s.City as city_name,
       COUNT(DISTINCT sch.TrainID) AS connecting_trains
FROM Schedules sch
JOIN Stations s ON sch.StationID = s.StationID
GROUP BY s.StationCode, city_name
ORDER BY connecting_trains DESC;

-- 21. Revenue per Train Type

SELECT tr.TrainType,
       SUM(tic.Fare) AS total_revenue
FROM Tickets tic
JOIN Trains tr ON tic.TrainID = tr.TrainID
GROUP BY tr.TrainType
ORDER BY total_revenue DESC;

-- 22. Peak Booking Hours

SELECT HOUR(BookingDateTime) AS hour,
       COUNT(*) AS bookings
FROM Tickets
GROUP BY hour
ORDER BY bookings DESC
LIMIT 3;

-- 23. Cancellation Reasons Analysis

SELECT CancellationReason,
       COUNT(*) AS count,
       AVG(RefundAmount) AS avg_refund
FROM Cancellations
GROUP BY CancellationReason
ORDER BY count DESC;

-- 24.  Payment Failure Analysis

SELECT p.PaymentMode,
       (SUM(CASE WHEN PaymentStatus = 'Failed' THEN 1 ELSE 0 END)/COUNT(*))*100 AS failure_rate
FROM Payments p
GROUP BY p.PaymentMode;

-- 25. Inter-Station Traffic

SELECT sch1.StationID AS from_stationID,
       sch2.StationID AS to_stationID,
       COUNT(*) AS passengers
FROM Tickets t
JOIN Schedules sch1 ON t.SourceStationID = sch1.StationID
JOIN Schedules sch2 ON t.DestinationStationID = sch2.StationID
GROUP BY from_stationID, to_stationID;

-- 26 Gender Distribution per Class

SELECT t.Class,
       p.Gender,
       COUNT(*) AS passengers
FROM Tickets t
JOIN Passengers p ON t.PassengerID = p.PassengerID
GROUP BY t.Class, p.Gender;

-- 27.  Seasonal Demand Analysis

SELECT MONTH(JourneyDate) AS month,
       COUNT(*) AS bookings
FROM Tickets
GROUP BY month
ORDER BY bookings DESC;

-- 28. Most Cancelled Trains

SELECT tr.TrainNumber, tr.TrainName, COUNT(*) AS cancellations
FROM Tickets t
JOIN Trains tr ON t.TrainID = tr.TrainID
WHERE t.Status = 'Cancelled'
GROUP BY tr.TrainNumber, tr.TrainName
ORDER BY cancellations DESC
LIMIT 5;

-- 29. Top Revenue-Generating Stations

SELECT s.StationName, SUM(t.Fare) AS revenue
FROM Tickets t
JOIN Stations s ON t.SourceStationID = s.StationID
GROUP BY s.StationName
ORDER BY revenue DESC
LIMIT 2;

-- 30. Find trains with least bookings in next 7 days for maintenance
SELECT t.TrainNumber, t.TrainName,
       COUNT(tk.TicketID) AS upcoming_bookings,
       (SELECT MAX(JourneyDate) FROM Tickets WHERE TrainID = t.TrainID) AS last_journey
FROM Trains t
LEFT JOIN Tickets tk ON t.TrainID = tk.TrainID 
  AND tk.JourneyDate BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY
WHERE t.IsActive = TRUE
GROUP BY t.TrainID
ORDER BY upcoming_bookings ASC
LIMIT 3;




  