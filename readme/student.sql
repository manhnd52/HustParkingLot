--I. Các thao tác đối với sinh viên--------------------------------------------------------

--0. Hàm lấy customerid từ mssv(hoặc mã vé của khách vãng lai)-----------------------------
CREATE OR REPLACE FUNCTION getcustomerid(input_mssv character varying) RETURNS integer
AS $$
DECLARE
	customer_id INT;
BEGIN
	IF length(input_mssv) = 8 THEN
		SELECT customerid INTO customer_id
		FROM student WHERE mssv = input_mssv;
	ELSE 
		SELECT customerid INTO customer_id
		FROM visitor WHERE ticketid::varchar = input_mssv;
	END IF;
	If customer_id IS NOT NULL then
			RETURN customer_id;
		ELSE
			RAISE 'Khong ton tai mssv';
		END IF;
END;
$$
LANGUAGE 'plpgsql';

--1. Số dư tài khoản------------------------------------------------------------------
SELECT balance FROM student WHERE mssv = '20225880';

--2. In ra các giao dịch--------------------------------------------------------------
SELECT  transactionid "Transaction ID",
		amount "Số tiền (đồng)",
		time "Thời gian", 
		CASE WHEN tranaction_type THEN 'Nạp tiền' ELSE 'Gửi xe' END "Loại giao dịch"
FROM    transaction
WHERE   customerId = getCustomerId('20225880');
--3. Nạp tiền gửi xe và trả về tài khoản của sinh viên, khi nạp tiền đồng thời tạo 1 giao dịch trong transaction

--Trigger tạo giao dịch khi có sinh viên nạp tiền--------------------------------------
CREATE OR REPLACE FUNCTION payin_log_func() RETURNS TRIGGER
AS $$
BEGIN
   INSERT INTO transaction (customerid, amount, time, tranaction_type)
   VALUES (getCustomerId(NEW.mssv), 
		   abs(OLD.balance - NEW.balance), 
		   current_timestamp, 
		   (OLD.balance - NEW.balance) < 0);
   RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER payin_log
AFTER UPDATE OF balance
ON student
FOR EACH ROW
EXECUTE FUNCTION payin_log_func();


UPDATE student
SET balance = balance + '10000'
WHERE mssv = '20225880'
RETURNING balance;

--4. In ra vị trí xe------------------------------------------------------------
SELECT  parking_lot.name, parkingspotid
FROM parking_spot
NATURAL JOIN PARKING_LOT
NATURAL JOIN park 
NATURAL JOIN now_vehicle
WHERE customerId = getCustomerId('20225880') and exit_time IS NULL;


--5. Thay đổi mật khẩu----------------------------------------------------------
UPDATE student 
SET password = ''
WHERE mssv = '20225880';
