CREATE TABLE Passengers (
    PassengerID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Age TINYINT UNSIGNED NOT NULL,
    Gender ENUM('Male', 'Female', 'Other', 'Prefer not to say') NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(20) NOT NULL,
    Disability BOOLEAN DEFAULT FALSE,
    Address VARCHAR(255),
    City VARCHAR(50),
    State VARCHAR(50),
    Country VARCHAR(50) DEFAULT 'India'
);

CREATE TABLE Stations (
    StationID INT AUTO_INCREMENT PRIMARY KEY,
    StationName VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    State VARCHAR(50),
    StationCode VARCHAR(5) UNIQUE COMMENT 'Short code like "NDLS" for New Delhi',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Classes (
    ClassName ENUM('1AC', '2AC', '3AC', 'Sleeper', 'General') PRIMARY KEY,
    FarePerKilometer DECIMAL(8,2) NOT NULL
);

CREATE TABLE Concessions (
    Category ENUM('Senior Citizen', 'Student', 'Disability') PRIMARY KEY,
    ConcessionPercentage DECIMAL(5,2) NOT NULL
);

CREATE TABLE Trains (
    TrainID INT AUTO_INCREMENT PRIMARY KEY,
    TrainNumber VARCHAR(10) UNIQUE NOT NULL COMMENT 'e.g. 12345',
    TrainName VARCHAR(100) NOT NULL,
    TrainType ENUM('Superfast', 'Express', 'Passenger', 'Rajdhani', 'Shatabdi', 'Duronto', 'Vande Bharat', 'Garib Rath', 'Other') NOT NULL,
    OriginStationID INT NOT NULL,
    DestinationStationID INT NOT NULL,
    TotalDistance INT UNSIGNED COMMENT 'In kilometers',
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (OriginStationID) REFERENCES Stations(StationID),
    FOREIGN KEY (DestinationStationID) REFERENCES Stations(StationID)
);

CREATE TABLE Schedules (
    ScheduleID INT AUTO_INCREMENT PRIMARY KEY,
    TrainID INT NOT NULL,
    StationID INT NOT NULL,
    StationSerialNo INT NOT NULL COMMENT 'Order of station in route (1,2,3...)',
    ArrivalTime TIME,
    DepartureTime TIME,
    DistanceFromOrigin INT UNSIGNED COMMENT 'In kilometers',
    DayNumber TINYINT UNSIGNED COMMENT 'Day of journey (1 for first day)',
    IsOnMonday BOOLEAN DEFAULT TRUE,
    IsOnTuesday BOOLEAN DEFAULT TRUE,
    IsOnWednesday BOOLEAN DEFAULT TRUE,
    IsOnThursday BOOLEAN DEFAULT TRUE,
    IsOnFriday BOOLEAN DEFAULT TRUE,
    IsOnSaturday BOOLEAN DEFAULT TRUE,
    IsOnSunday BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID),
    FOREIGN KEY (StationID) REFERENCES Stations(StationID),
    UNIQUE KEY (TrainID, StationID),
    UNIQUE KEY (TrainID, StationSerialNo)
);

CREATE TABLE Seats (
    SeatID INT AUTO_INCREMENT PRIMARY KEY,
    TrainID INT NOT NULL,
    CoachNo VARCHAR(10) NOT NULL COMMENT 'e.g. A1, B2, etc.',
    SeatNo VARCHAR(10) NOT NULL COMMENT 'e.g. 1, 2, 3... or LB/UB etc.',
    Class ENUM('1AC', '2AC', '3AC', 'Sleeper', 'General') NOT NULL,
    IsRAC BOOLEAN DEFAULT FALSE,
    IsBooked BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID),
    FOREIGN KEY (Class) REFERENCES Classes(ClassName),
    UNIQUE KEY (TrainID, CoachNo, SeatNo)
);

CREATE TABLE Tickets (
    TicketID INT AUTO_INCREMENT PRIMARY KEY,
    PNRNo VARCHAR(10) UNIQUE NOT NULL COMMENT '6-char alphanumeric',
    PassengerID INT NOT NULL,
    TrainID INT NOT NULL,
    Class ENUM('1AC', '2AC', '3AC', 'Sleeper', 'General') NOT NULL,
    JourneyDate DATE NOT NULL,
    BookingDateTime DATETIME NOT NULL,
    Status ENUM('Confirmed', 'WL', 'RAC', 'Cancelled') NOT NULL,
    SeatNo VARCHAR(10) COMMENT 'Null if WL',
    CoachNo VARCHAR(10) COMMENT 'Null if WL',
    ConcessionAmount DECIMAL(10,2) DEFAULT 0.00,
    SourceStationID INT NOT NULL,
    DestinationStationID INT NOT NULL,
    ScheduleID INT NOT NULL COMMENT 'Reference to train schedule',
    Fare DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID),
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID),
    FOREIGN KEY (Class) REFERENCES Classes(ClassName),
    FOREIGN KEY (SourceStationID) REFERENCES Stations(StationID),
    FOREIGN KEY (DestinationStationID) REFERENCES Stations(StationID),
    FOREIGN KEY (ScheduleID) REFERENCES Schedules(ScheduleID)
);

CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    TicketID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMode ENUM('Credit Card', 'Debit Card', 'Net Banking', 'UPI', 'Wallet', 'Cash') NOT NULL,
    PaymentStatus ENUM('Pending', 'Completed', 'Failed', 'Refunded') NOT NULL,
    TransactionID VARCHAR(50) UNIQUE,
    TransactionDateTime DATETIME NOT NULL,
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID)
);

CREATE TABLE Cancellations (
    CancellationID INT AUTO_INCREMENT PRIMARY KEY,
    TicketID INT NOT NULL UNIQUE,
    CancellationDateTime DATETIME NOT NULL,
    RefundAmount DECIMAL(10,2) NOT NULL,
    RefundStatus ENUM('Pending', 'Processed', 'Failed') NOT NULL,
    CancellationReason VARCHAR(255),
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID)
);

CREATE TABLE Notifications (
    NotificationID INT AUTO_INCREMENT PRIMARY KEY,
    PassengerID INT NOT NULL,
    TicketID INT NOT NULL,
    Message VARCHAR(255) NOT NULL,
    CreatedAt DATETIME NOT NULL default now(),
    FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID),
    Foreign Key(TicketID) REFERENCES Tickets(TicketID)
);





