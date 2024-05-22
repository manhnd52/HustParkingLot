-- CREATE TABLE CUSTOMER(
-- 	CustomerID SERIAL PRIMARY KEY,
-- 	CustomerType BOOL
-- );

-- CREATE TABLE VISITOR(
-- 	CustomerID INT PRIMARY KEY,
-- 	TicketID UUID DEFAULT gen_random_uuid(), 
-- 	FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
-- );

-- CREATE TABLE STUDENT(
-- 	CustomerID INT PRIMARY KEY,
-- 	fullname VARCHAR(255), 
-- 	mssv VARCHAR(8) UNIQUE,
-- 	balance int DEFAULT 0,
-- 	password varchar,
-- 	FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
-- );

-- CREATE TABLE TRANSACTION (
--  	transactionID SERIAL PRIMARY KEY,
--  	MSSV VARCHAR(8), 
-- 	amount INT, 
-- 	time TIMESTAMP, 
-- 	tranaction_type BOOL,
-- 	FOREIGN KEY (MSSV) REFERENCES Student(MSSV) 
-- );

-- CREATE TABLE VEHICLE_TYPE (
-- 	vehicleTypeID SERIAL PRIMARY KEY,
-- 	name VARCHAR(15), 
-- 	price INT CHECK (price >= 0)
-- );

-- CREATE TABLE VEHICLE (
-- 	vehicleID SERIAL PRIMARY KEY,
-- 	vehicleTypeID INT, 
-- 	license_plate VARCHAR(15), 
-- 	color VARCHAR(15),
-- 	customerID INT, 
-- 	FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
-- 	FOREIGN KEY (vehicleTypeID) REFERENCES vehicle_type(vehicleTypeID)
-- );

-- CREATE TABLE spot_type (
-- 	spotTypeID SERIAL PRIMARY KEY, 
-- 	vehicleType BOOL,
-- 	isPrivileged BOOL
-- );

-- CREATE TABLE PARKING_LOT (
-- 	parkingLotID SERIAL PRIMARY KEY, 
-- 	name VARCHAR(16),
-- 	capacity INT
-- )

-- CREATE TABLE STAFF (
-- 	StaffID SERIAL PRIMARY KEY,
-- 	fullname VARCHAR (256),
-- 	password VARCHAR CHECK (length(password) >= 8),
-- 	parkinglotid INT,
-- 	FOREIGN KEY (parkinglotid) REFERENCES PARKING_LOT(parkinglotid)
-- );

-- CREATE TABLE PARKING_SPOT (
-- 	parkingspotID SERIAL PRIMARY KEY,
-- 	spotTypeID INT, 
-- 	parkingLotID INT, 
-- 	occupied BOOL DEFAULT false,
-- 	FOREIGN KEY (spotTypeID) REFERENCES SPOT_TYPE(spotTypeID),
-- 	FOREIGN KEY (parkingLotID) REFERENCES PARKING_LOT(parkinglotid)
-- );

-- CREATE TABLE PARK (
-- 	ParkID SERIAL PRIMARY KEY, 
-- 	VehicleID INT, 
-- 	ParkingSpotID INT,
-- 	entry_time TIMESTAMP,
-- 	exit_time TIMESTAMP,
-- 	FOREIGN KEY (parkingSpotID) REFERENCES PARKING_SPOT(parkingSpotID),
-- 	FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID)
-- )
	