INSERT INTO Stations (StationName, City, State, StationCode) VALUES
('Chhatrapati Shivaji Terminus', 'Mumbai', 'Maharashtra', 'CSMT'),
('New Delhi', 'Delhi', 'Delhi', 'NDLS'),
('Howrah Junction', 'Kolkata', 'West Bengal', 'HWH'),
('Chennai Central', 'Chennai', 'Tamil Nadu', 'MAS'),
('Bengaluru City', 'Bengaluru', 'Karnataka', 'SBC'),
('Secunderabad Junction', 'Hyderabad', 'Telangana', 'SC'),
('Ahmedabad Junction', 'Ahmedabad', 'Gujarat', 'ADI'),
('Pune Junction', 'Pune', 'Maharashtra', 'PUNE'),
('Jaipur Junction', 'Jaipur', 'Rajasthan', 'JP'),
('Lucknow Charbagh', 'Lucknow', 'Uttar Pradesh', 'LKO'),
('Patna Junction', 'Patna', 'Bihar', 'PNBE'),
('Thiruvananthapuram Central', 'Thiruvananthapuram', 'Kerala', 'TVC'),
('Bhopal Junction', 'Bhopal', 'Madhya Pradesh', 'BPL'),
('Guwahati', 'Guwahati', 'Assam', 'GHY'),
('Nagpur Junction', 'Nagpur', 'Maharashtra', 'NGP'),
('Visakhapatnam Junction', 'Visakhapatnam', 'Andhra Pradesh', 'VSKP'),
('Chandigarh Junction', 'Chandigarh', 'Punjab', 'CDG'),
('Coimbatore Junction', 'Coimbatore', 'Tamil Nadu', 'CBE'),
('Madurai Junction', 'Madurai', 'Tamil Nadu', 'MDU'),
('Varanasi Junction', 'Varanasi', 'Uttar Pradesh', 'BSB');

INSERT INTO Passengers (FirstName, LastName, Age, Gender, Email, Phone, Disability, City) VALUES
('Aarav', 'Sharma', 28, 'Male', 'aarav.s@mail.com', '9123456780', FALSE, 'Mumbai'),
('Ananya', 'Patel', 35, 'Female', 'ananya.p@mail.com', '9123456781', FALSE, 'Delhi'),
('Rohan', 'Singh', 67, 'Male', 'rohan.s@mail.com', '9123456782', FALSE, 'Kolkata'),
('Priya', 'Gupta', 19, 'Female', 'priya.g@mail.com', '9123456783', FALSE, 'Chennai'),
('Vikram', 'Reddy', 42, 'Male', 'vikram.r@mail.com', '9123456784', TRUE, 'Bengaluru'),
('Neha', 'Verma', 22, 'Female', 'neha.v@mail.com', '9123456785', FALSE, 'Hyderabad'),
('Arjun', 'Malhotra', 71, 'Male', 'arjun.m@mail.com', '9123456786', FALSE, 'Ahmedabad'),
('Sneha', 'Joshi', 29, 'Female', 'sneha.j@mail.com', '9123456787', FALSE, 'Pune'),
('Rahul', 'Kumar', 45, 'Male', 'rahul.k@mail.com', '9123456788', TRUE, 'Jaipur'),
('Pooja', 'Shah', 31, 'Female', 'pooja.s@mail.com', '9123456789', FALSE, 'Lucknow'),
('Amit', 'Yadav', 53, 'Male', 'amit.y@mail.com', '9123456790', FALSE, 'Patna'),
('Divya', 'Nair', 24, 'Female', 'divya.n@mail.com', '9123456791', FALSE, 'Thiruvananthapuram'),
('Sanjay', 'Mishra', 38, 'Male', 'sanjay.m@mail.com', '9123456792', FALSE, 'Bhopal'),
('Anjali', 'Das', 63, 'Female', 'anjali.d@mail.com', '9123456793', FALSE, 'Guwahati'),
('Karthik', 'Rao', 27, 'Male', 'karthik.r@mail.com', '9123456794', FALSE, 'Nagpur'),
('Meera', 'Khan', 33, 'Female', 'meera.k@mail.com', '9123456795', TRUE, 'Visakhapatnam'),
('Rajesh', 'Pillai', 58, 'Male', 'rajesh.p@mail.com', '9123456796', FALSE, 'Chandigarh'),
('Sonia', 'Menon', 41, 'Female', 'sonia.m@mail.com', '9123456797', FALSE, 'Coimbatore'),
('Vivek', 'Srinivasan', 36, 'Male', 'vivek.s@mail.com', '9123456798', FALSE, 'Madurai'),
('Nisha', 'Choudhury', 47, 'Female', 'nisha.c@mail.com', '9123456799', FALSE, 'Varanasi'),
('Alok', 'Bose', 29, 'Male', 'alok.b@mail.com', '9123456700', FALSE, 'Kolkata'),
('Isha', 'Rajput', 31, 'Female', 'isha.r@mail.com', '9123456701', FALSE, 'Delhi'),
('Deepak', 'Mehra', 65, 'Male', 'deepak.m@mail.com', '9123456702', FALSE, 'Mumbai'),
('Swati', 'Ganguly', 22, 'Female', 'swati.g@mail.com', '9123456703', FALSE, 'Chennai'),
('Manoj', 'Chatterjee', 43, 'Male', 'manoj.c@mail.com', '9123456704', TRUE, 'Bengaluru');

INSERT INTO Classes (ClassName, FarePerKilometer) VALUES
('1AC', 5.00), ('2AC', 4.00), ('3AC', 3.50), 
('Sleeper', 2.00);

INSERT INTO Concessions (Category, ConcessionPercentage) VALUES
('Senior Citizen', 40.00), ('Student', 50.00), ('Disability', 75.00);


INSERT INTO Trains (TrainNumber, TrainName, TrainType, OriginStationID, DestinationStationID, TotalDistance) VALUES
('12001', 'Shatabdi Express', 'Shatabdi', 2, 5, 2150),
('12002', 'Shatabdi Express', 'Shatabdi', 5, 2, 2150),
('12951', 'Rajdhani Express', 'Rajdhani', 2, 1, 1384),
('12952', 'Rajdhani Express', 'Rajdhani', 1, 2, 1384),
('12635', 'Chennai Express', 'Express', 4, 1, 1336),
('12636', 'Chennai Express', 'Express', 1, 4, 1336),
('12509', 'Guwahati Express', 'Express', 14, 2, 1872),
('12510', 'Guwahati Express', 'Express', 2, 14, 1872),
('12723', 'Telangana Express', 'Express', 6, 16, 781),
('12724', 'Telangana Express', 'Express', 16, 6, 781),
('12863', 'Howrah Mail', 'Superfast', 3, 2, 1448),
('12864', 'Howrah Mail', 'Superfast', 2, 3, 1448),
('12933', 'Golden Temple Mail', 'Superfast', 1, 17, 1965),
('12934', 'Golden Temple Mail', 'Superfast', 17, 1, 1965),
('12645', 'Grand Trunk Express', 'Express', 4, 20, 800),
('12646', 'Grand Trunk Express', 'Express', 20, 4, 800),
('12779', 'Godavari Express', 'Express', 16, 19, 1200),
('12780', 'Godavari Express', 'Express', 19, 16, 1200),
('12229', 'Duronto Express', 'Duronto', 2, 7, 935),
('12230', 'Duronto Express', 'Duronto', 7, 2, 935),
('22643', 'Mumbai-Chennai Express', 'Express', 1, 4, 1336),
('22644', 'Chennai-Mumbai Express', 'Express', 4, 1, 1336),
('12875', 'Bengaluru-Howrah SF', 'Superfast', 5, 3, 1860),
('12876', 'Howrah-Bengaluru SF', 'Superfast', 3, 5, 1860);

INSERT INTO Schedules (TrainID, StationID, StationSerialNo, ArrivalTime, DepartureTime, DistanceFromOrigin, DayNumber) VALUES
(1, 2, 1, NULL, '06:00:00', 0, 1),
(1, 15, 2, '10:15:00', '10:20:00', 950, 1),
(1, 5, 3, '14:30:00', '14:35:00', 2150, 1),
(1, 8, 4, '16:30:00', '16:40:00', 2350, 1),
(1, 10, 5, '17:20:00',NULL, 2510, 1),
(3, 2, 1, NULL, '17:35:00', 0, 1),
(3, 15, 2, '21:20:00', '21:25:00', 824, 1),
(3, 8, 3, '02:15:00', '02:20:00', 1163, 1),
(3, 1, 4, '08:15:00', NULL, 1384, 2),
(41, 1, 1, NULL, '23:15:00', 0, 1),      -- Mumbai CST
(41, 15, 2, '04:30:00', '04:35:00', 824, 1),  -- Nagpur
(41, 16, 3, '11:20:00', '11:25:00', 1200, 1), -- Visakhapatnam
(41, 4, 4, '19:45:00', NULL, 1336, 2);       -- Chennai Central

INSERT INTO Tickets (PNRNo, PassengerID, TrainID, Class, JourneyDate, BookingDateTime, Status, SeatNo, CoachNo, SourceStationID, DestinationStationID, ScheduleID, Fare, ConcessionAmount) VALUES
('PNR1001', 1, 3, '2AC', '2024-03-25', NOW(), 'Confirmed', '1', 'B1', 2, 1, 3, 5536.00, 0.00),
('PNR1002', 3, 1, '3AC', '2024-04-01', NOW(), 'Confirmed', '1', 'C1', 2, 5, 1, 7525.00, 3010.00),
('PNR1003', 5, 3, '1AC', '2024-03-28', NOW(), 'WL', NULL, NULL, 2, 1, 3, 6920.00, 5190),
('PNR1004', 7, 3, 'Sleeper', '2024-03-25', NOW(), 'RAC', '1', 'S1', 2, 1, 3, 2768.00, 1107.2),
('PNR1005', 9, 1, '3AC', '2024-04-05', NOW(), 'Cancelled', '2', 'C1', 2, 5, 1, 7525.00, 5643.75);

INSERT INTO Tickets (PNRNo, PassengerID, TrainID, Class, JourneyDate, BookingDateTime, Status, SeatNo, CoachNo, SourceStationID, DestinationStationID, ScheduleID, Fare) VALUES
('PNR2001', 2, 41, '1AC', '2025-04-16', NOW(), 'Confirmed', '1', 'A1', 1, 4, 14, 6680.00),
('PNR2002', 4, 41, '2AC', '2025-04-16', NOW(), 'Confirmed', '1', 'B1', 1, 16, 14, 4800.00),
('PNR2003', 6, 41, 'Sleeper', '2025-04-15', NOW(), 'WL', NULL, NULL, 1, 4, 14, 2672.00),
('PNR2004', 8, 41, '2AC', '2025-04-18', NOW(), 'WL', NULL, NULL, 15, 4, 15, 3200.00),
('PNR2005', 10, 41, 'Sleeper', '2025-04-28', NOW(), 'RAC', '1', 'R1', 1, 4, 14, 2672.00),
('PNR2006', 12, 41, '1AC', '2025-04-22', NOW(), 'Cancelled', '2', 'A1', 1, 4, 14, 6680.00),
('PNR2007', 14, 41, 'Sleeper', '2025-04-25', NOW(), 'Confirmed', '2', 'S1', 15, 4, , 2004.00);

INSERT INTO Payments (TicketID, Amount, PaymentMode, PaymentStatus, TransactionID, TransactionDateTime) VALUES
(1, 5536.00, 'Credit Card', 'Completed', 'TXN1001', NOW()),
(2, 7525.00, 'Debit Card', 'Completed', 'TXN1002', NOW()),
(3, 6920.00, 'UPI', 'Pending', 'TXN1003', NOW()),
(4, 2768.00, 'Net Banking', 'Completed', 'TXN1004', NOW()),
(5, 7525.00, 'Wallet', 'Refunded', 'TXN1005', NOW()),
(37, 6680.00, 'Credit Card', 'Completed', 'TXN2001','2025-04-15 18:11:16'),
(38, 4800.00, 'Debit Card', 'Completed', 'TXN2002','2025-04-15 18:11:16'),
(39, 2672.00, 'UPI', 'Pending', 'TXN2003','2025-04-15 18:11:16'),
(40, 3200.00, 'Net Banking', 'Completed', 'TXN2004','2025-04-15 18:11:16'),
(41, 2672.00, 'Wallet', 'Completed', 'TXN2005','2025-04-15 18:11:16'),
(42, 6680.00, 'Credit Card', 'Refunded', 'TXN2006','2025-04-15 18:11:16'),
(43, 2004.00, 'Cash', 'Completed', 'TXN2007','2025-04-15 18:11:16');

INSERT INTO Cancellations (TicketID, CancellationDateTime, RefundAmount, RefundStatus, CancellationReason) VALUES
(5, NOW(), 6772.50, 'Processed', 'Change of plans'),
(3, NOW(), 6228.00, 'Pending', 'Duplicate booking');

INSERT INTO Cancellations (TicketID, CancellationDateTime, RefundAmount, RefundStatus, CancellationReason) VALUES
(42, NOW(), 6012.00, 'Processed', 'Emergency cancellation');




-- Train 12951 (Rajdhani Express)
INSERT INTO Seats (TrainID, CoachNo, SeatNo, Class, IsRAC) VALUES
(3, 'A1', '1', '1AC', FALSE),
(3, 'A1', '2', '1AC', FALSE),
(3, 'B1', '1', '2AC', FALSE),
(3, 'B1', '2', '2AC', FALSE),
(3, 'S1', '1', 'Sleeper', FALSE),
(3, 'S1', '2', 'Sleeper', TRUE), -- RAC
(41, 'A1', '1', '1AC'), (41, 'A1', '2', '1AC'),
(41, 'B1', '1', '2AC'), (41, 'B1', '2', '2AC'),
(41, 'S1', '1', 'Sleeper'), (41, 'S1', '2', 'Sleeper'),
(41, 'R1', '1', 'Sleeper'), (41, 'R1', '2', 'Sleeper'); -- RAC seats

-- Train 12001 (Shatabdi Express)
INSERT INTO Seats (TrainID, CoachNo, SeatNo, Class, IsRAC) VALUES
(1, 'C1', '1', '3AC', FALSE),
(1, 'C1', '2', '3AC', FALSE),
(1, 'C1', '3', '3AC', FALSE);

INSERT INTO Notifications (PassengerID, Message, CreatedAt, TicketID) VALUES 
	(1, CONCAT('Your ticket ', (select PNRNo from Tickets where TicketID = 1), ' has been confirmed!'), NOW(), 1),
    (3, CONCAT('Your ticket ', (select PNRNo from Tickets where TicketID = 2), ' has been confirmed!'), NOW(), 2),
    (2, CONCAT('Your ticket ', (select PNRNo from Tickets where TicketID = 37), ' has been confirmed!'), NOW(), 37),
    (4, CONCAT('Your ticket ', (select PNRNo from Tickets where TicketID = 38), ' has been confirmed!'), NOW(), 38);

ALter table Seats add isBooked Boolean;
update Seats set isBooked = True where TrainID = 3 and CoachNo = 'A1' and SeatNo = '1';
update Seats set isBooked = False where TrainID = 3 and CoachNo = 'A1' and SeatNo = '2';
update Seats set isBooked = True where TrainID = 3 and CoachNo = 'B1' and SeatNo = '1';
update Seats set isBooked = False where TrainID = 3 and CoachNo = 'B1' and SeatNo = '2';
update Seats set isBooked = True where TrainID = 3 and CoachNo = 'S1' and SeatNo = '1';
update Seats set isBooked = False where TrainID = 3 and CoachNo = 'S1' and SeatNo = '2';

update Seats set isBooked = True where TrainID = 1 and CoachNo = 'C1' and SeatNo = '1';
update Seats set isBooked = False where TrainID = 1 and CoachNo = 'C1' and SeatNo = '2';
update Seats set isBooked = False where TrainID = 1 and CoachNo = 'C1' and SeatNo = '3';

alter table seats drop isAvailable;

ALter table Seats add JourneyDate date;
update Seats set JourneyDate = '2025-04-10' where TrainID = 3 and CoachNo = 'A1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-10' where TrainID = 3 and CoachNo = 'A1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-10' where TrainID = 3 and CoachNo = 'B1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-10' where TrainID = 3 and CoachNo = 'B1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-10' where TrainID = 3 and CoachNo = 'S1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-10' where TrainID = 3 and CoachNo = 'S1' and SeatNo = '2';

update Seats set JourneyDate = '2025-04-10' where TrainID = 1 and CoachNo = 'C1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-10' where TrainID = 1 and CoachNo = 'C1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-10' where TrainID = 1 and CoachNo = 'C1' and SeatNo = '3';

update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'A1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'A1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'B1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'B1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'S1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'S1' and SeatNo = '2';

update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'A1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'A1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'B1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'B1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'S1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'S1' and SeatNo = '2';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'R1' and SeatNo = '1';
update Seats set JourneyDate = '2025-04-20' where TrainID = 41 and CoachNo = 'R1' and SeatNo = '2';


update Tickets set JourneyDate = '2025-04-18' where TicketID = 3;
update Tickets set JourneyDate = '2025-04-28' where TicketID = 1;
update Tickets set JourneyDate = '2025-05-01' where TicketID = 2;
update Tickets set JourneyDate = '2025-05-05' where TicketID = 4;
update Tickets set JourneyDate = '2025-05-20' where TicketID = 5 ;
select date('2025-04-13 12:10:41');

update cancellations set CancellationDatetime = '2025-03-27 12:10:41' where CancellationID = 1;
update cancellations set CancellationDatetime = '2025-04-10 12:10:41' where CancellationID = 2;
update cancellations set CancellationDatetime = '2025-04-05 12:10:41' where CancellationID = 5;

update seats set TrainID = 41 where SeatID = 34 or SeatID = 35;
update seats set isBooked = False where SeatID between 0 and 100;


update seats set isBooked = True where TrainID = 3 and SeatNo = 1 and CoachNo = 'B1';
update seats set isBooked = True where TrainID = 1 and SeatNo = 1 and CoachNo = 'C1';
update seats set isBooked = True where TrainID = 3 and SeatNo = 1 and CoachNo = 'S1';
update seats set isBooked = True where TrainID = 1 and SeatNo = 2 and CoachNo = 'C1';
update seats set isBooked = True where TrainID = 41 and SeatNo = 1 and CoachNo = 'A1';
update seats set isBooked = True where TrainID = 41 and SeatNo = 1 and CoachNo = 'A1';
update seats set isBooked = True where TrainID = 41 and SeatNo = 1 and CoachNo = 'R1';
update seats set isBooked = True where TrainID = 41 and SeatNo = 2 and CoachNo = 'A1';
update seats set isBooked = True where TrainID = 41 and SeatNo = 2 and CoachNo = 'S1';