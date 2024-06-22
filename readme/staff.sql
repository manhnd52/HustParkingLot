--II. Thao tác đối với nhân viên------------------------------------------------------------------


1. Khi xe vào
--1. Cho xe máy vào bãi---------------------------------------------------------------------------
SELECT DISTINCT vehicletypeid, name, size, price FROM vehicle_type ORDER BY vehicletypeid ASC;

--a. Kiểm tra xem còn đủ chỗ hay không------------------------------------------------------------


--Hàm lấy ID bãi đỗ xe của nhân viên có ID = '2'--------------------------------------------------
CREATE OR REPLACE FUNCTION getparkinglotid(input_staffid integer) RETURNS integer
AS $$
DECLARE
	parkinglot int;
BEGIN
	SELECT parkinglotid INTO parkinglot FROM staff where staffid = input_staffid;
	RETURN parkinglot;
END;
$$
LANGUAGE 'plpgsql';

--Hàm lấy một ví trí xe còn trống với id của bãi đỗ xe và kích cỡ loại xe--------------------------
CREATE OR REPLACE FUNCTION getavailablespots(input_parkinglotid integer, input_size integer) RETURNS integer
AS $$
DECLARE
	spot_id int;
BEGIN
	SELECT parkingspotid INTO spot_id
	FROM parking_spot p
	WHERE 
		parkinglotid = input_parkinglotid
		AND input_size = (SELECT size FROM spot_type s WHERE p.spottypeid = s.spottypeid)
		AND NOT occupied 
	ORDER BY parkingspotid
	LIMIT 1;
	RETURN spot_id;
END;
$$
LANGUAGE 'plpgsql';

SELECT  getavailableSpots(getParkingLotId('2'), '1');

--b. Gửi xe---------------------------------------------------------------------------
---th1. Xe của sinh viên--------------------------------------------------------------
-----Nhập vào mssv: kích hoạt TRIGGER kiểm tra xem thẻ sinh viên này đã gửi xe chưa---

----- Lấy thông tin số dư---------------------------
SELECT balance FROM student WHERE mssv = '20225880';
UPDATE student SET balance = balance - 2000 WHERE mssv = '20225880'; 

CREATE OR REPLACE FUNCTION check_one_vehicle_per_student() RETURNS TRIGGER
AS $$
BEGIN
    -- Kiểm tra xem có xe nào của student vẫn đang được gửi
    IF EXISTS (
		SELECT 1
		FROM park JOIN now_vehicle USING(vehicleId)
		WHERE customerId = (SELECT customerId
							FROM now_vehicle n WHERE n.vehicleId = NEW.vehicleId)
			AND exit_time IS NULL
    ) THEN
        -- Nếu có, báo lỗi và không cho phép chèn bản ghi mới
        RAISE EXCEPTION 'Mỗi sinh viên chỉ được gửi một xe tại một thời điểm';
    END IF;
    -- Nếu không có xe nào đang gửi, cho phép chèn bản ghi mới
    RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER trigger_check_one_vehicle_per_student
BEFORE INSERT
ON park
FOR EACH ROW
EXECUTE FUNCTION check_one_vehicle_per_student();



---th2. Xe của khách vãng lai-----------------------------------------------------
-----Lấy thông tin xe vào---------------------------------------------------------
-----Cấp vé-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION addvisitor() RETURNS character varying
AS $$
DECLARE
	id int;
	ticket varchar;
BEGIN
	INSERT INTO Customer(CustomerType)
	VALUES(true)
	RETURNING customerid INTO id;
	INSERT INTO Visitor(customerid)
	VALUES(id)
	RETURNING ticketid INTO ticket;
	RETURN ticket;
END;
$$
LANGUAGE 'plpgsql';
SELECT addvisitor();

---- Lưu lại giao dịch của visitor------------------------------------------
INSERT INTO transaction VALUE();

--c. Lưu lại thông tin xe của khách hàng------------------------------------
--Kiểm tra xem thông tin của xe đã được lưu hay chưa------------------------
--Thêm thông tin xe vào database--------------------------------------------
INSERT INTO now_vehicle (customerId, vehicletypeid, license_plate, color) 
VALUES (getCustomerId('20225880'), '1', '29a12345', 'red');

--Kích hoạt trigger cập nhật vị trí đã được đỗ------------------------------
CREATE OR REPLACE FUNCTION is_occuppied() RETURNS trigger
AS $$
BEGIN
	UPDATE parking_spot
	SET occupied = TRUE
	WHERE parkingspotid = new.parkingspotid;
	RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER auto_update_occupied
AFTER INSERT
ON park
FOR EACH ROW
WHEN (new.exit_time IS NULL)
EXECUTE FUNCTION is_occuppied();

--2. Cho xe ra bãi--------------------------------------------------------------
----1. Đối với sinh viên--------------------------------------------------------
-----Kiểm tra xe của sinh viên có đúng với xe đã gửi vào không------------------
SELECT 	license_plate, color, vehicleTypeId, parking_lot.name
FROM 	now_vehicle 
		JOIN park USING (vehicleid)
		NATURAL JOIN parking_spot
		NATURAL JOIN parking_lot
WHERE 	customerId = getCustomerId('20225880') 
AND 	exit_time IS NULL;

----2. Đối với khách vãng lai-----------------------------------------------------
-----Kiểm tra xe của khách hàng có đúng với xe đã gửi vào không-------------------
cursor.execute("SELECT license_plate, color, vehicleid FROM now_vehicle WHERE customerId = getCustomerId(%s)", (ticket,))
info = cursor.fetchone()
license_plate, color, vehicleid = info
cursor.execute("SELECT parking_lot.name FROM park NATURAL JOIN parking_spot NATURAL JOIN parking_lot WHERE vehicleid = %s", (vehicleid,))
## if (lot != staff_login_info["parkname"]): ...

----Gọi hàm cho xe ra, đồng thời kích hoạt trigger cập nhật occupied thành false--
----TRIGGER cập nhật occupied-----------------------------------------------------
CREATE OR REPLACE FUNCTION update_parking_spot_status() RETURNS trigger
AS $$
BEGIN
    -- Kiểm tra nếu exit_time được đặt (từ NULL sang một giá trị không NULL)
    IF NEW.exit_time IS NOT NULL AND OLD.exit_time IS NULL THEN
        -- Cập nhật bảng parking_spot, đặt occupied thành FALSE
		RAISE NOTICE 'REAL';
        UPDATE parking_spot
        SET occupied = FALSE
        WHERE parkingspotid = NEW.parkingspotid;
    END IF;
    RETURN NEW;
END;
LANGUAGE 'plpgsql'
$$;

CREATE OR REPLACE TRIGGER set_exit_time_trigger
AFTER UPDATE OF exit_time
ON park
FOR EACH ROW
WHEN (old.exit_time IS NULL AND new.exit_time IS NOT NULL)
EXECUTE FUNCTION update_parking_spot_status();
---Cập nhật exit_time------------------------------------------------------------
CREATE OR REPLACE PROCEDURE vehicle_out(IN string character varying)
AS $$
DECLARE
	x int;
BEGIN
	IF length(string) = 8 THEN
		UPDATE park
		SET exit_time = now()
		FROM now_vehicle, student
		WHERE park.exit_time IS NULL
		AND park.vehicleId = now_vehicle.vehicleId
		AND now_vehicle.customerid = getCustomerId(string);
	ELSE
		-- Dành cho vé
		UPDATE park
		SET exit_time = now()
		WHERE park.vehicleid = 
		(SELECT vehicleid 
		 FROM now_vehicle 
		 WHERE customerid = getCustomerId(string))
		RETURNING parkId INTO x;
		IF (x IS NULL) THEN RAISE 'Vé không đúng';
		END IF;
	END IF;
END;
$$
LANGUAGE 'plpgsql';

CALL vehicle_out('20225880');
--3. Cập nhật mật khẩu-----------------------------------------------------------------------
UPDATE staff 
SET password = '12345678'
WHERE staffid = '2';