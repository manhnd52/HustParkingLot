--1. Quản lý sinh viên---------------------------------------------------------------

----a. Thêm sinh viên----------------------------------------------------------------
------ Gọi hàm addstudent()----------------------------------------------------------
CREATE OR REPLACE PROCEDURE addstudent(
	IN in_mssv integer,
	IN in_name character varying)
AS $$
DECLARE
	id int;
BEGIN
	INSERT INTO Customer(customertype) 
	VALUES (false)
	RETURNING customerid INTO id;
	INSERT INTO Student(customerid, fullname, mssv) 
	VALUES (id, in_name, in_mssv);
END;
$$
LANGUAGE 'plpgsql';

CALL addstudent('20225636','Lê Huy');

----b. Sửa thông tin sinh viên----------------------------------------------------------
UPDATE student SET fullname = 'Nguyễn Đức Mạnh' WHERE mssv = '20225880';
UPDATE student SET password = '888888' WHERE mssv = '20225880';
UPDATE student SET balance = '999999' WHERE mssv = '20225880';

----c. In danh sách sinh viên-----------------------------------------------------------
SELECT * FROM student;

--2. Quản lý nhân viên------------------------------------------------------------------

----a. In danh sách nhân viên-----------------------------------------------------------
SELECT staffid "Staff ID", 
	fullname "Họ và Tên",
	password "Mật khẩu",
	parking_lot.name "Bãi đỗ xe" 
FROM staff NATURAL JOIN parking_lot;

----b. Thêm nhân viên-------------------------------------------------------------------
INSERT INTO Staff(fullname, parkinglotid) VALUES('Hoài Nam','6');

----c. Sửa nhân viên--------------------------------------------------------------------
UPDATE staff SET fullname = 'Nguyễn Hoài Nam' WHERE staffid = '6';
UPDATE staff SET password = '88888888' WHERE staffid = '6';
UPDATE staff SET parkinglotid = '2' WHERE staffid = '6';

----d. Duyệt đơn đăng ký----------------------------------------------------------------
SELECT fullname, email FROM application;
----- Trong trường hợp đồng ý tuyển-----------------------------------------------------
INSERT INTO staff(fullname, parkinglotid) VALUES('Lê Huy', '2');
----- Xóa đơn đăng ký đã xem xét--------------------------------------------------------
DELETE FROM application WHERE fullname = 'Lê Huy' AND email = 'huy@gmail.com';

--3. Doanh thu bãi đỗ xe----------------------------------------------------------------

----a. Doanh thu theo ngày--------------------------------------------------------------

SELECT  
		time::date "Ngày",
		SUM(amount) "Doanh thu",
		COUNT(transactionid) "Số lượng giao dịch"
FROM    transaction
WHERE   tranaction_type = false
GROUP BY time::date HAVING time::date = '2024-6-19'
UNION 
SELECT  
		time::date "Ngày",
		SUM(amount) "Doanh thu",
		COUNT(transactionid) "Số lượng giao dịch"
FROM    transaction
WHERE   tranaction_type = false
GROUP BY time::date HAVING time::date = '2024-5-31';
----b. Doanh thu theo tháng------------------------------------------------------------
SELECT  
	date_part('year', time) "Năm",
	date_part('month', time) "Tháng",
	SUM(amount) "Doanh thu",
	COUNT(transactionid) "Số lượng giao dịch"
FROM    transaction
WHERE   tranaction_type = false
GROUP BY date_part('year', time), date_part('month', time)
HAVING date_part('year', time) = 2024 AND date_part('month', time) = 6;

----c. Doanh thu theo năm----------------------------------------------------------------
SELECT  SUM(amount) "Doanh thu",
		COUNT(transactionid) "Số lượng giao dịch"
FROM    transaction
WHERE   date_part('year', time) = 2024 and tranaction_type = false;