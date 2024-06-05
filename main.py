import re
import psycopg2
from tabulate import tabulate
import os
from getpass import getpass
import random 
from datetime import datetime, timedelta
import smtplib
import imaplib
import email
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.header import decode_header
from account import conn_params, host_email, host_password
import matplotlib.pyplot as plt


# Thiết lập thông tin kết nối
DATABASE_URL = "postgresql://aefxhjyk:mvcwwnkrihotyjymxixe@alpha.india.mkdb.sh:5432/aqatqqkl"

# Từ điển màu sắc
color_translation = {
    "red": "đỏ",
    "orange": "cam",
    "yellow": "vàng",
    "green": "xanh lá cây",
    "blue": "xanh dương",
    "purple": "tím",
    "pink": "hồng",
    "brown": "nâu",
    "black": "đen",
    "white": "trắng",
    "gray": "xám",
    "cyan": "xanh nước biển",
}

mssv_regex = r"^20\d{6}$" # Mã số sinh viên phải bắt đầu bằng 20 và có 8 chữ số (regular expression)
date_regex = r"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[012])/(19|20)\d\d$"
email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
month_regex = r"^(0[1-9]|1[0-2])/(19|20)\d\d$"
year_regex = r"^(19|20)\d\d$"


# Các hàm hỗ trợ
def convert_date(date):
    return datetime.strptime(date, "%d/%m/%Y").strftime("%Y-%m-%d")

# staff_login_info lưu thông tin đăng nhập global dùng cho các hàm liên quan
staff_login_info = {
    "staffid": 0,
    "fullname": "",
    "parkname": ""
}

# student_login_info
student_login_info = {
    "mssv": "",
    "fullname": "",
    "password": ""
}

def reset_all_login_info():
    staff_login_info["staffid"] = 0
    staff_login_info["fullname"] = ""
    staff_login_info["parkname"] = ""
    student_login_info["mssv"] = ""
    student_login_info["fullname"] = ""
    

# Các câu lệnh điều khiển
def command(*func):
    while True:
        cmd = int(input("Command: "))
        if cmd > len(func) or cmd <= 0:
            print("Vui lòng nhập lại!")
        else: 
            func[cmd - 1]()
            break

def renhanh(number, *func):
    func[number]()

def xoamanhinh(): 
    os.system('cls')                    # Dùng để xóa màn hình terminal

# Scene
def menu():
    xoamanhinh()
    print("Xin chào")
    print("1. Login")
    print("2. Sign Up")
    print("3. 25Queries")
    command(login, signup)

def login():
    xoamanhinh()
    print("Bạn là: ")
    print("1. Sinh viên")
    print("2. Nhân viên")
    print("3. Admin")
    command(student_login, staff_login, admin_login)

def student_login(): 
    xoamanhinh()
    mssv = input("MSSV: ")
    password = getpass("Password: ")
    fullname = ''
    i = 0
    # Cần truy vấn cơ sở dữ liệu để kiểm tra tài khoản mật khẩu
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            cursor.execute("SELECT fullname, password FROM student WHERE mssv = %s", (mssv,))
            value = cursor.fetchone()
            if value:
                if value[1] == password: 
                    student_login_info["fullname"] = value[0]
                    student_login_info["mssv"] = mssv
                    success_student_login()
                    return
    fail_login()

def success_student_login(): 
    xoamanhinh()
    print("Xin chào, {}".format(student_login_info["fullname"]))
    print("Bạn đã đăng nhập thành công. Bạn cần hỗ trợ gì?")
    print("1. Số dư của tôi là bao nhiêu?")
    print("2. Nạp tiền")
    print("3. Xe của tôi đang ở đâu?")
    print("4. Lịch sử giao dịch")
    print("5. Đổi mật khẩu")
    print("6. Log out")
    command(balance, payin, vehiclePosition, transactionHistory, std_changePassword,logout)

def balance():
    xoamanhinh()
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            cursor.execute("SELECT balance FROM STUDENT WHERE mssv = %s", (student_login_info["mssv"],))
            balance = cursor.fetchone()
            print("Số tiền còn lại của bạn là " + str(balance[0]) + " đồng.")   
    if not balance[0]: 
        print("Bạn đã hết tiền. Xin vui lòng nạp thêm tiền để có thể sử dụng dịch vụ đỗ xe!")
    print("1. Quay lại")
    print("2. Exit")
    command(success_student_login, exit)

def transactionHistory(): 
    xoamanhinh()  
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor :  
            cursor.execute("""
            SELECT  transactionid "Transaction ID",
                    amount "Số tiền (đồng)",
                    time "Thời gian", 
                    CASE WHEN tranaction_type THEN 'Nạp tiền' ELSE 'Gửi xe' END "Loại giao dịch"
            FROM    transaction
            WHERE   customerId = getCustomerId(%s)
            """, (student_login_info["mssv"],))
            rows = cursor.fetchall();
            if rows:
                header = [des[0] for des in cursor.description]
                print("Lịch sử giao dịch của bạn là: ")
                stop_loop = False
                # In 5 dòng tranaction 1 lần và có thể dừng bằng KeyboardInterupt 
                while not stop_loop:
                    for i in range(0, len(rows), 5):
                        print(tabulate(rows[i:i+5], headers=header, tablefmt="github"))
                        try:
                            if (i > len(rows) - 5): 
                                raise KeyboardInterrupt
                            input("Nhấn Enter để xem tiếp, hoặc nhấn Ctrl + C để dừng...\n")
                        except KeyboardInterrupt:
                            stop_loop = True;
                            break
                    else:
                        break  
            else:
                print("Bạn chưa thực hiện giao dịch nào. Vui lòng quay lại sau.")
    print("1. Quay lại")
    print("2. Exit")
    command(success_student_login, exit)

def payin():
    xoamanhinh()
    while 1: 
        amount = int(input("Nhập số tiền bạn muốn nạp (đồng): "))
        if amount > 0: break
        else: print("Vui lòng nhập số tiền phù hợp")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            try:
                cursor.execute("""
                UPDATE student
                SET balance = balance + %s
                WHERE mssv = %s
                RETURNING balance
                """, (amount, student_login_info["mssv"]))
                print("\033[32mGiao dịch thành công!\033[0m")
                print("Số dư trong tài khoản của bạn là " + str(cursor.fetchone()[0]) + " đồng.")
            except: 
                print("\033[31mGiao dịch thất bại! Vui lòng thử lại sau\033[0m")
    print("1. Quay lại")
    print("2. Exit")
    command(success_student_login, exit)

def vehiclePosition():
    xoamanhinh()
    with psycopg2.connect(**conn_params) as conn:
         with conn.cursor() as cursor: 
            cursor.execute ("""
                SELECT  parking_lot.name, parkingspotid, color, license_plate 
                FROM    parking_spot
                        NATURAL JOIN PARKING_LOT
                        NATURAL JOIN park 
                        NATURAL JOIN now_vehicle
                WHERE   customerId = getCustomerId(%s) and exit_time IS NULL
            """, (student_login_info["mssv"],))
            row = cursor.fetchone(); 
            if row:
                lot = row[0]
                spot = row[1]
                color = row[2]
                license_plate = row[3]
                print("Xe của bạn đang ở bãi đỗ xe {0} tại ô {1}.".format(lot, spot))
                print("Tips: Xe của bạn có màu " + color_translation.get(color) + " với biển số " + license_plate + ".")
            else: 
                print("Bạn chưa gửi xe!")         
    print("1. Quay lại")
    print("2. Exit")
    command(success_student_login, exit)

def std_changePassword():
    xoamanhinh()
    newPassword = input("Nhập mật khẩu mới: ") 
    verify = input("Xác nhận lại mật khẩu: ")
    if verify == newPassword:
        with psycopg2.connect(**conn_params) as conn:
            with conn.cursor() as cursor:
                try:   
                    cursor.execute("""
                    UPDATE student 
                    SET password = %s
                    WHERE mssv = %s
                    """, (newPassword, student_login_info["mssv"]))
                    print("Update thành công")
                except: 
                    print("Lỗi hệ thống")  
    else:
        print("Mật khẩu xác thực không đúng")
        print("1. Thử lại")
        print("2. Quay lại")
        command(std_changePassword, success_student_login)
        return   
    print("1. Quay lại")
    print("2. Exit")
    command(success_student_login, exit)

def staff_login():
    xoamanhinh()
    print("Nhân viên đăng nhập")
    staffid = input("Staff ID: ")
    password = getpass("Password: ")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            cursor.execute("""SELECT fullname, password, name
                           FROM staff INNER JOIN parking_lot USING (parkinglotid)
                           WHERE staffid = %s""", (staffid,))
            value = cursor.fetchone()
            if value:
                if value[1] == password: 
                    staff_login_info["staffid"] = staffid
                    staff_login_info["password"] = password
                    staff_login_info["fullname"] = value[0]
                    staff_login_info["parkname"] = value[2]
                    success_staff_login()    # value[2] là tên của bãi đỗ xe
                    return
            fail_login()
    
def success_staff_login():
    xoamanhinh()
    print("Xin chào, {}".format(staff_login_info["fullname"]))
    print("Bãi đỗ xe {} chúc bạn một ngày làm việc hiệu quả!".format(staff_login_info["parkname"]))
    print("1. Work")
    print("2. Thông tin")
    print("3. Thay đổi mật khẩu")
    print("4. Log out")
    command(staff_work, staff_info, staff_changePassword, logout)

def staff_work():
    xoamanhinh ()
    print("[BÃI ĐỖ XE {}]".format(staff_login_info["parkname"]))
    print("Khách hàng là: ")
    print("1. Sinh viên")
    print("2. Khách vãng lai")
    print("3. Quay lại")
    command(student_work, visitor_work, success_staff_login)

def chonloaixe():       # hàm trả về vị trí để xe trong bãi
    xoamanhinh()
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
                print("Chọn loại xe: ")
                cursor.execute("SELECT DISTINCT vehicletypeid, name, size, price FROM vehicle_type ORDER BY vehicletypeid ASC")
                # tạo ra dictionnary lưu thông tin các loại xe
                rows = {row[0]: (row[1], row[2], row[3]) for row in cursor.fetchall()} 
                for i, row in rows.items():
                    print(f"{i}. {row[0]}")
                vehicleTypeId = int(input("Loại xe (nhập ID): "))
                size  = rows[vehicleTypeId][1]
                price = rows[vehicleTypeId][2] 
                cursor.execute("""
                SELECT  getavailableSpots(getParkingLotId(%s), %s)              
                """, (staff_login_info["staffid"], size))
                return (vehicleTypeId, spotId := cursor.fetchone()[0], price)
    
def student_work():
    xoamanhinh()
    print("1. Vào bãi")
    print("2. Ra bãi")
    print("3. Quay lại")
    command(student_in, student_out, staff_work)
    staff_work()    

def student_in():
    vehicleTypeId, spotId, price = chonloaixe()
    if spotId:
        with psycopg2.connect(**conn_params) as conn:
            with conn.cursor() as cursor:
                try:
                    xoamanhinh()
                    print("Nhập thông tin")
                    print("***DEMO QUÉT THẺ SINH VIÊN***")
                    mssv = input("MSSV: ")
                    cursor.execute("SELECT balance FROM student WHERE mssv = %s", (mssv,))
                    balance = cursor.fetchone();
                    if balance is None:
                        print("Mã số sinh viên không tồn tại!")
                        input("Nhấn Enter để tiếp tục...")
                        staff_work()
                        return
                    balance = balance[0] # chuyển từ tuple sang int
                    if balance >= price:
                        print("***DEMO CHO QUÉT HÌNH ẢNH XE VÀ BIỂN SỐ XE***")
                        if color := input("Màu xe") not in color_translation.keys():
                            print("Màu xe không hợp lệ!")
                            input("Nhấn Enter để tiếp tục...")
                        # kiểm tra xe này đẫ có trong danh sách xe từng đỗ ở bãi không?
                        vehicleId = None
                        if vehicleTypeId != 2:
                            license_plate = input("Biển số xe: ")
                            # Có thể 1 xe được nhiều sinh viên dùng chung
                            cursor.execute("SELECT vehicleId FROM now_vehicle WHERE license_plate = %s AND customerId = getCustomerId(%s) AND vehicletypeid = %s", (license_plate, mssv, vehicleTypeId))
                            vehicleId = cursor.fetchone()   # tuple chứa vehicleId
                            if vehicleId is None:
                                cursor.execute("INSERT INTO now_vehicle (customerId, vehicletypeid, license_plate, color) VALUES (getCustomerId(%s)1, %s, %s, %s) RETURNING vehicleId", (mssv, vehicleTypeId, license_plate, color))
                                vehicleId = cursor.fetchone()

                        if vehicleTypeId == 2:  # Nếu là xe đạp

                            # nếu có xe đạp cùng màu rồi thì không cần thêm vào bảng now_vehicle
                            cursor.execute("""
                                            SELECT vehicleid 
                                            FROM now_vehicle
                                            WHERE customerid = getCustomerId(%s)
                                            AND vehicletypeid = %s
                                            AND color = %s
                                           """, (mssv, vehicleTypeId, color))
                            vehicleId = cursor.fetchone()
                            if vehicleId is None:
                                cursor.execute("""
                                INSERT INTO 
                                    now_vehicle (customerId, 
                                               vehicletypeid, 
                                               license_plate, 
                                               color) 
                                VALUES (getCustomerId(%s), %s, null, %s) 
                                RETURNING vehicleId""", 
                                (mssv, vehicleTypeId, color)
                                )
                                vehicleId = cursor.fetchone()
                        vehicleId = vehicleId[0]
                        cursor.execute("INSERT INTO park (vehicleid, parkingspotid) VALUES (%s, %s)", (vehicleId, spotId))
                        # trừ tiền trong tài khoản
                        cursor.execute("UPDATE student SET balance = balance - %s WHERE mssv = %s", (price, mssv))     
                        print("\033[32mBạn hãy để xe ở chỗ {}\033[0m".format(spotId))
                    else: 
                        print("\033[31mBạn không còn đủ tiền trong tài khoản!\033[0m")
                except psycopg2.IntegrityError as e:
                    print("\033[31mSinh viên đã gửi xe rồi!\033[0m ")
                    conn.rollback()
                except psycopg2.Error as e:
                    print("\033[31mMỗi sinh viên chỉ được gửi một xe tại một thời điểm!\033[0m")
                    conn.rollback()
                except Exception as e:
                    print("Gửi xe thất bại do xảy ra lỗi hệ thống!")
                    print(e)
                    conn.rollback()
    else:
        print("Bãi đỗ xe không còn vị trí cho xe này!")
    input("Nhấn Enter để tiếp tục...")
    staff_work()
           
def student_out():
    xoamanhinh()
    print("Ra bãi")
    mssv = input("Mã số sinh viên: ")
    with psycopg2.connect(**conn_params) as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                               SELECT license_plate, color, vehicleTypeId
                               FROM now_vehicle JOIN park USING (vehicleid)
                               WHERE customerId = getCustomerId(%s) 
                               AND exit_time IS NULL""",  (mssv,))
                info = cursor.fetchone()
                if info is None:
                    print("\033[91mSinh viên không có xe trong bãi!\033[0m")
                    input("Nhấn Enter để tiếp tục...")
                    staff_work()
                    return
                else:
                    license_plate, color, vehicleTypeId = info
    print("***DEMO CHO QUÉT THÔNG TIN XE***")
    print("1. Xe máy")
    print("2. Xe đạp")
    print("3. Ô tô")
    input_vehicleTypeId = int(input("Loại xe: "))
    if input_vehicleTypeId != vehicleTypeId:
        print("\033[91mĐây không phải là xe của bạn!\033[0m")
        input("Nhấn Enter để tiếp tục...")
        staff_work()
        return
    # kiểm tra có lấy đúng xe không
    if input_vehicleTypeId != 2:
        input_lisence_plate = input("Biển số xe: ")
        if license_plate != input_lisence_plate:
            print("\033[91mĐây không phải là xe của bạn!\033[0m")
            input("Nhấn Enter để tiếp tục...")
            staff_work()
            return
    else: 
        print("[", end="")
        for colorItem in color_translation.keys():
            print(colorItem, end=", ")
        print("...]")
        input_color = input("Màu xe: ")
        if color != input_color:
            print("\033[91mĐây không phải là xe của bạn!\033[0m")
            input("Nhấn Enter để tiếp tục...")
            staff_work()
            return

    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("CALL vehicle_out(%s)", (mssv,))
                print("\033[92mRa bãi thành công!\033[0m")
            except:
                print("Ra bãi thất bại do xảy ra lỗi hệ thống!")
    input("Nhấn Enter để tiếp tục...")
    staff_work()
    
def visitor_work():
    xoamanhinh()
    print("1. Vào bãi")
    print("2. Ra bãi")
    command(visitor_in, visitor_out)

def visitor_in():
    xoamanhinh() 
    vehicleTypeId, spotId, price = chonloaixe()
    print("Tiền vé: {0} đồng".format(price))
    paid = int(input("Khách hàng đã trả tiền (1/0)? "))
    if not paid:
        input("Nhấn Enter để quay lại...")
        staff_work()
        return
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                xoamanhinh()
                cursor.execute("SELECT addvisitor()")
                ticket = cursor.fetchone()[0]
                print("Nhập thông tin")
                print("***DEMO CHO QUÉT HÌNH ẢNH XE VÀ BIỂN SỐ XE***")
                license_plate = input("Biển số xe: ")
                color = input("Màu xe: ")
                cursor.execute("INSERT INTO now_vehicle (vehicletypeid, license_plate, color, customerid) VALUES (%s, %s, %s, getCustomerId(%s)) RETURNING vehicleId", (vehicleTypeId, license_plate, color, ticket))
                vehicleId = cursor.fetchone()[0]
                cursor.execute("INSERT INTO park (vehicleid, parkingspotid) VALUES (%s, %s)", (vehicleId, spotId))
                cursor.execute("INSERT INTO transaction (customerId, amount, tranaction_type) VALUES (getCustomerId(%s), %s, false)", (ticket, price))
                print("Vé của bạn là " + str(ticket) + ". Hãy giữ vé để ra bãi!")
                print(f"Bạn hãy để xe ở chỗ {spotId}!")
            except psycopg2.errors as e:
                print("Gửi xe thất bại do xảy ra lỗi hệ thống!" + str(e))
    input("Nhấn Enter để tiếp tục...")
    staff_work()

def visitor_out():
    xoamanhinh()
    print("***DEMO QUÉT VÉ***")
    ticket = input("Nhập vé: ")
    input_license_plate = input("Biển số xe: ")
    input_color = input("Màu xe: ")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("SELECT license_plate, color, vehicleTypeId FROM now_vehicle WHERE customerId = getCustomerId(%s)", (ticket,))
                info = cursor.fetchone()
                license_plate, color, vehicleTypeId = info
                if license_plate != input_license_plate or color != input_color:
                    print("\033[91mĐây không phải là xe của bạn!\033[0m")
                    input("Nhấn Enter để tiếp tục...")
                    staff_work()
                    return
                cursor.execute("CALL vehicle_out(%s)", (ticket,))
                print("\033[1;32mRa bãi thành công!\033[0m")
            except:
                print("Vé không hợp lệ!")
    input("Nhấn Enter để tiếp tục...")
    staff_work()

def staff_info():
    pass

def staff_changePassword():
    xoamanhinh()
    print("Thay đổi mật khẩu")
    while (verify := getpass("Nhập mật khẩu cũ: ")) != staff_login_info["password"]:
        print("Mật khẩu cũ không đúng!")
        input("Nhấn Enter để đăng nhập lại...")
        staff_login()
        return
    while 1: 
        newPassword = getpass("Nhập mật khẩu mới: ")
        verify = getpass("Xác nhận lại mật khẩu: ")
        if len(newPassword) >= 8 and verify == newPassword: break
        else: print("Vui lòng thử lại!")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:   
                cursor.execute("""
                UPDATE staff 
                SET password = %s
                WHERE staffid = %s
                """, (newPassword, staff_login_info["staffid"]))
                print("Update thành công")
            except: 
                input("Mật khẩu của bạn không đúng định dạng!")
                staff_changePassword()
                return
    input("Nhấn Enter để đăng nhập lại...")
    staff_login()
    

countLogin = 0      # Đếm số lần đăng nhập admin sai

def admin_login():
    xoamanhinh()
    global countLogin     
    if countLogin != 3:
        # print with font weight = bold
        print("\033[1m[ADMIN LOGIN]\033[0m")
        # Print with italic style
        print("\033[3mDont login if you are not admin.\033[0m")
        
        if int(input("Continue (1/0): ")): 
            password = getpass("Password: ")
            if password == '123456':
                countLogin = 0
                success_admin_login()        
            else:
                countLogin +=1
                fail_login()
        else: 
            login()
    else: 
        print("Bạn không còn quyền truy cập với tư cách Admin!")
        print("1. Quay lại")
        print("2. Liên hệ Đức Mạnh để cấp quyền truy cập")
        command(login, exit)

def success_admin_login():
    xoamanhinh()
    print("Xin chào, bạn đang truy cập với quyền Admin.")
    print("1. Quản lý sinh viên")
    print("2. Quản lý nhân viên")
    print("3. Quản lý bãi đỗ xe")
    print("4. Quản lý cơ sở dữ liệu")
    print("5. Quản lý doanh thu")
    print("6. Log out")
    command(student_manage, staff_manage, parkLot_manage, database_manage, revenue_manage, logout)

def student_manage():
    xoamanhinh()
    print("\033[1mQuản lý sinh viên\033[0m")
    print("1. Thêm")
    print("2. Xóa")
    print("3. Sửa")
    print("4. Duyệt")
    print("5. Quay lại")
    command(addStudent, deleteStudent, modifyStudent, reviewStudent, success_admin_login)

def addStudent():
    xoamanhinh()
    print("Thêm sinh viên")
    name = input("Hãy nhập tên sinh viên: ")
    while True:
        mssv = input("Mã số sinh viên: ") 
        if re.match(mssv_regex, mssv): break        # Kiểm tra mã số sinh viên có hợp lệ không   bằng regex
        else: print("Mã số sinh viên không hợp lệ! Mã số sinh viên phải bắt đầu bằng 20 và có 8 chữ số.")

    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                cursor.execute("CALL addStudent(%s, %s)", (mssv, name))
                print(f"Thêm {name} thành công! Mật khẩu mặc định của sinh viên là '123456'.")
            except psycopg2.IntegrityError as e:
                    print("Mã số sinh viên đã tồn tại!")
            except:
                print("Thêm sinh viên thất bại do xảy ra lỗi!")

    print("1. Thêm sinh viên khác")
    print("2. Quay lại")
    command(addStudent, student_manage)

def deleteStudent():
    xoamanhinh()
    print("Xóa sinh viên")
    mssv = input("Mã số sinh viên: ")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                cursor.execute("SELECT fullname FROM student WHERE mssv = %s", (mssv,))
                name = cursor.fetchone()
                print(f"Có phải là {name[0]} không?")
                if int(input("1. Có\n2. Không\nCommand: ")) == 1:
                    cursor.execute("DELETE FROM student WHERE mssv = %s", (mssv,))
                    print(f"Xóa sinh viên {mssv} thành công!")
            except psycopg2.IntegrityError:
                    print("Mã số sinh viên không tồn tại!")
            except:
                print("Xóa sinh viên thất bại do xảy ra lỗi!")
    print("1. Xóa sinh viên khác")
    print("2. Quay lại")
    command(deleteStudent, student_manage)

def modifyStudent():
    xoamanhinh()
    print("Sửa thông tin sinh viên")
    mssv = input("Mã số sinh viên cần sửa: ")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                cursor.execute("SELECT fullname FROM student WHERE mssv = %s", (mssv,))
                student = cursor.fetchone()
                if student:
                    print(f"Sinh viên hiện tại: {student[0]}")
                    new_name = input("Nhập tên mới (nhấn Enter để giữ nguyên): ") or student[0]
                    cursor.execute("UPDATE student SET fullname = %s WHERE mssv = %s", (new_name, mssv))
                    conn.commit()
                    print(f"Cập nhật thông tin sinh viên {mssv} thành công!")
                else:
                    print("Không tìm thấy sinh viên với MSSV đã nhập.")
            except Exception as e:
                print(f"Sửa thông tin sinh viên thất bại do xảy ra lỗi: {e}")
    
    print("1. Sửa thông tin sinh viên khác")
    print("2. Quay lại")
    command(modifyStudent, student_manage)

def reviewStudent():
    xoamanhinh()
    print("Duyệt thông tin sinh viên")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                cursor.execute("SELECT mssv, fullname FROM student")
                students = cursor.fetchall()
                if students:
                    for student in students:
                        print(f"MSSV: {student[0]}, Tên: {student[1]}")
                else:
                    print("Không có sinh viên nào trong cơ sở dữ liệu.")
            except Exception as e:
                print(f"Duyệt thông tin sinh viên thất bại do xảy ra lỗi: {e}")
    
    print("1. Duyệt lại")
    print("2. Quay lại")
    command(reviewStudent, student_manage)


def staff_manage():
    xoamanhinh()
    print("Quản lý nhân viên")
    print("1. Danh sách nhân viên")
    print("2. Thêm")
    print("3. Xóa")
    print("4. Sửa")
    print("5. Duyệt CV")
    print("6. Quay lại")
    command(print_staff, addStaff, deleteStaff, modifyStaff, reviewStaff, success_admin_login)

def print_staff():
    xoamanhinh()
    print("[DANH SÁCH NHÂN VIÊN]")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                cursor.execute("""SELECT staffid "Staff ID", 
                                        fullname "Họ và Tên",
                                        password "Mật khẩu",
                                        parking_lot.name "Bãi đỗ xe" 
                                FROM staff NATURAL JOIN parking_lot""")
                rows = cursor.fetchall()
                if rows:
                    header = [des[0] for des in cursor.description]
                    stop_loop = False
                    while not stop_loop:
                        for i in range(0, len(rows),5):
                            print(tabulate(rows[i:i+5], headers=header, tablefmt="github"))
                            try:
                                if (i > len(rows) - 5): 
                                    raise KeyboardInterrupt
                                input("Nhấn Enter để xem tiếp, hoặc nhấn Ctrl + C để dừng...\n")
                            except KeyboardInterrupt:
                                stop_loop = True
                                break
                        else:
                            break  
                else:
                    print("Không có nhân viên nào cả.")
                    
            except Exception as e:
                print(f"Đã xảy ra lỗi khi thực hiện truy vấn: {e}")
    input("Nhấn Enter để quay lại...")
    staff_manage()
        

def addStaff():
    xoamanhinh()
    print("[THÊM NHÂN VIÊN]")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                name = input("Tên nhân viên: ")
                while True:
                    print("Bãi đỗ xe:")
                    cursor.execute("SELECT name FROM parking_lot ORDER BY parkinglotid ASC")
                    parkinglots = cursor.fetchall()
                    for i, lot in enumerate(parkinglots):
                        print(f"{i + 1}. {lot[0]}")
                    parkinglot = input("Tên bãi đỗ xe: ")
                    cursor.execute("SELECT parkinglotid FROM parking_lot WHERE name = %s", (parkinglot,))
                    parkinglot = cursor.fetchone()
                    if parkinglot:
                        parkinglot = parkinglot[0]
                        break
                    else: 
                        xoamanhinh()
                        print("\033[31mBãi đỗ xe không tồn tại!\033[0m")
                cursor.execute("INSERT INTO Staff(fullname, parkinglotid) VALUES(%s, %s) RETURNING staffid", (name, parkinglot))
                staffid = cursor.fetchone()[0]
                print(f"\033[32mThêm nhân viên {name} thành công!\033[0m") 
                print(f"Staff ID của nhân viên là {staffid}")
                print( "Mật khẩu mặc định của nhân viên là '12345678'.")
            except:
                 print("\033[31mThêm nhân viên thất bại do xảy ra lỗi!\033[0m")

    print("1. Thêm nhân viên khác")
    print("2. Quay lại")
    command(addStaff, staff_manage)

def deleteStaff():
    xoamanhinh()
    print("[XÓA NHÂN VIÊN]")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                id = input("Staff ID: ")
                check = int(input("Chắc chắn muốn xóa (Xóa(1)/ Thôii(0)): "))
                if check:
                    cursor.execute("DELETE FROM staff WHERE staffid = %s", (id,))
                    conn.commit()
                    print("\033[32mXóa thành công.\033[0m")
            except Exception as e:
                print(f"Đã xảy ra lỗi: {e}")
    print("1. Xóa nhân viên khác")
    print("2. Quay lại")
    command(deleteStaff, staff_manage)

def modifyStaff():
    xoamanhinh()
    print("[SỬA NHÂN VIÊN]")
    print("Command template: (command)-(ID)-(nội dung)")
    str = input("Nhập: ")
    str = str.split('-')
    cmd = str[0]
    id = str[1]
    content = str[2]
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor:
            try:
                if cmd == "ModifyName":
                    cursor.execute("UPDATE staff SET fullname = %s WHERE staffid = %s",(content,id))
                    print("\033[32mĐổi tên thành công.\033[0m")
                elif cmd == "ModifyPassword":
                    cursor.execute("UPDATE staff SET password = %s WHERE staffid = %s",(content,id))
                    print("\033[32mĐổi mật khẩu thành công.\033[0m")
                elif cmd == "ModifyParkingLot":
                    cursor.execute("UPDATE staff SET parkinglot = %s WHERE staffid = %s",(content,id))
                    print("\033[32mThay đổi nơi làm việc thành công.\033[0m")
                conn.commit()
            except:
                print("Error")
    print("1. Tiếp tục sửa")
    print("2. Quay lại")
    command(modifyStaff, staff_manage)

def reviewStaff():
    xoamanhinh()
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor:
            try:
                cursor.execute("SELECT fullname, email FROM application")
                rows = cursor.fetchall()
                if rows:
                    header = [des[0] for des in cursor.description]
                    stop_loop = False
                    while not stop_loop:
                        for i in range(0, len(rows)):
                            xoamanhinh()
                            print("Duyệt đăng kí: ")
                            print(f"Đơn thứ {i + 1}")
                            print(tabulate(rows[i:i + 1], headers=header, tablefmt="github"))
                            print("CV của ứng viên: ")
                            email = rows[i][1]
                            printCV(email)
                            print("1. Chấp nhận")
                            print("2. Từ chối")
                            print("3. Quyết định sau...")
                            func1 = lambda email=email, row_value=rows[i][0]: staff_accept(email, row_value)
                            func2 = lambda email=email, row_value=rows[i][0]: staff_deny(email, row_value)
                            command(func1,func2,func3)    
                            try:
                                input("Nhấn Enter để xem tiếp, hoặc nhấn Ctrl + C để dừng...\n")
                            except KeyboardInterrupt:
                                stop_loop = True
                                break
                        else:
                            break  
                else:
                    print("Không có đơn đăng kí nào cả.")
            except Exception as e:
                print(f"Đã xảy ra lỗi: {e}")
    input()
    staff_manage()

def printCV(user_email):
    # Thông tin kết nối đến server email
    username = host_email
    password = host_password
    imap_url = 'imap.gmail.com'

    # Địa chỉ email mà bạn muốn lọc và lấy nội dung
    target_email = user_email

    # Kết nối đến server IMAP
    mail = imaplib.IMAP4_SSL(imap_url)
    mail.login(username, password)
    mail.select('inbox')

    # Tìm kiếm email từ địa chỉ email cụ thể
    status, messages = mail.search(None, f'FROM "{target_email}"')

    # Lấy danh sách email IDs
    email_ids = messages[0].split()

    if not email_ids:
        print("Không có email nào từ địa chỉ này.")
    else:
        for email_id in email_ids:
            # Lấy email theo ID
            status, msg_data = mail.fetch(email_id, '(RFC822)')
            for response_part in msg_data:
                if isinstance(response_part, tuple):
                    msg = email.message_from_bytes(response_part[1])
                    subject, encoding = decode_header(msg['Subject'])[0]
                    if isinstance(subject, bytes):
                        subject = subject.decode(encoding if encoding else 'utf-8')
                    from_ = msg.get('From')
                    date = msg.get('Date')
                    
                    # Kiểm tra nếu email có nhiều phần
                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get('Content-Disposition'))
                            if 'attachment' not in content_disposition:
                                # Lấy phần chính của email
                                if content_type == 'text/plain':
                                    body = part.get_payload(decode=True).decode()
                                    print(f'Subject: {subject}')
                                    print(f'From: {from_}')
                                    print(f'Date: {date}')
                                    print(f'Body:\n{body}\n{"-"*50}\n')
                    else:
                        # Email không có nhiều phần
                        content_type = msg.get_content_type()
                        body = msg.get_payload(decode=True).decode()
                        print(f'Subject: {subject}')
                        print(f'From: {from_}')
                        print(f'Date: {date}')
                        print(f'Body:\n{body}\n{"-"*50}\n')

def staff_accept(user_email,name):
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor:
            try:
                while True:
                    print("Chọn bãi đỗ xe:")
                    cursor.execute("SELECT name FROM parking_lot")
                    parkinglots = cursor.fetchall()
                    for i, lot in enumerate(parkinglots):
                        print(f"{i + 1}. {lot[0]}")
                    parkinglot = input("Tên bãi đỗ xe: ")
                    cursor.execute("SELECT parkinglotid FROM parking_lot WHERE name = %s", (parkinglot,))
                    parkinglot = cursor.fetchone()
                    if parkinglot:
                        parkinglot = parkinglot[0]
                        break
                    else: 
                        print("Bãi đỗ xe không tồn tại!")
                cursor.execute("INSERT INTO staff(fullname, parkinglotid) VALUES(%s, %s) RETURNING staffid", (name, parkinglot))
                staffid = cursor.fetchone()[0]
            except Exception as e:
                print(f"Đã xảy ra lỗi khi thực hiện truy vấn: {e}")
            try:
                cursor.execute("DELETE FROM application WHERE fullname = %s AND email = %s",(name,user_email))
            except Exception as e:
                print(f"Đã xảy ra lỗi khi thực hiện truy vấn: {e}")
    sender_email = host_email
    sender_password = host_password
    subject = "Thư mời nhận việc"
    body = f""" Bạn đã được nhận vào làm.
                Tài khoản của bạn:
                    staff_id: {staffid}
                    password: 12345678
                Hãy đổi mật khẩu tài khoản của bạn.
                Về các chế độ khác đến văn phòng của chúng tôi tại D35-102 để biết chi tiết.
            """
    message = MIMEMultipart()
    message['From'] = sender_email
    message['To'] = user_email
    message['Subject'] = subject
    message.attach(MIMEText(body, 'plain'))
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        text = message.as_string()
        server.sendmail(sender_email, user_email, text)
    except Exception as e:
        print(f"Failed to send email. Error: {e}")
        print("Không thể gửi email, vui lòng kiểm tra lại địa chỉ email của bạn.")
        return
    
def staff_deny(user_email,name):
    sender_email = host_email
    sender_password = host_password
    subject = "Thư cảm ơn"
    body = f""" Cảm ơn bạn đã quan tâm đến công việc này nhưng bạn chưa phải ứng viên phù hợp mà chúng tôi tìm kiếm.
                Mong được sự quan tâm đăng kí của bạn trong những lần sau.
            """
    message = MIMEMultipart()
    message['From'] = sender_email
    message['To'] = user_email
    message['Subject'] = subject
    message.attach(MIMEText(body, 'plain'))
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor:
            try:
                cursor.execute("DELETE FROM application WHERE fullname = %s AND email = %s",(name,user_email))
            except Exception as e:
                print(f"Đã xảy ra lỗi khi thực hiện truy vấn: {e}")
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        text = message.as_string()
        server.sendmail(sender_email, user_email, text)
    except Exception as e:
        print(f"Failed to send email. Error: {e}")
        print("Không thể gửi email, vui lòng kiểm tra lại địa chỉ email của bạn.")
        signup()
        return

def func3():
    pass

def parkLot_manage():
    xoamanhinh()
    print("\033[1mQuản lý bãi đỗ xe\033[0m")
    print("1. Thêm")
    print("2. Xóa")
    print("3. Sửa")
    print("4. Duyệt")
    print("5. Quay lại")
    command(addParkLot, deleteParkLot, modifyParkLot, reviewParkLot, success_admin_login)

def addParkLot():
    xoamanhinh()
    print("Thêm bãi đỗ xe")
    name = input("Nhập tên bãi đỗ xe: ")
    while True:
        try:
            capacity = int(input("Nhập sức chứa của bãi đỗ xe: "))
            break
        except ValueError:
            print("Giá trị nhập vào không hợp lệ, vui lòng nhập lại.")

    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("INSERT INTO parking_lot (name, capacity) VALUES (%s, %s)", (name, capacity))
                conn.commit()
                print("Thêm bãi đỗ xe thành công!")
            except psycopg2.IntegrityError:
                print("Tên bãi đỗ xe đã tồn tại!")
            except Exception as e:
                print(f"Thêm bãi đỗ xe thất bại do xảy ra lỗi: {e}")

    print("1. Thêm bãi đỗ xe khác")
    print("2. Quay lại")
    command(addParkLot, parkLot_manage)

def deleteParkLot():
    xoamanhinh()
    print("Xóa bãi đỗ xe")
    parking_lot_id = input("Nhập ID bãi đỗ xe: ")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("SELECT name FROM parking_lot WHERE parkinglotid = %s", (parking_lot_id,))
                name = cursor.fetchone()
                if name:
                    print("\033[31mXóa bãi đỗ xe đồng nghĩa với việc xóa tất cả các chỗ đỗ xe và nhân viên quản lý của bãi đó.\033[0m")
                    print(f"Có phải là bãi đỗ xe '{name[0]}' không?")
                    if int(input("1. Có\n2. Không\nCommand: ")) == 1:
                        cursor.execute("DELETE FROM parking_spot WHERE parkinglotid = %s", (parking_lot_id,))
                        cursor.execute("DELETE FROM staff WHERE parkinglotid = %s", (parking_lot_id,))
                        cursor.execute("DELETE FROM parking_lot WHERE parkinglotid = %s ", (parking_lot_id,))
                        conn.commit()
                        print(f"Xóa bãi đỗ xe {parking_lot_id} thành công!")
                else:
                    print("Không tìm thấy bãi đỗ xe với ID đã nhập.")
            except Exception as e:
                print(f"Xóa bãi đỗ xe thất bại do xảy ra lỗi: {e}")

    print("1. Xóa bãi đỗ xe khác")
    print("2. Quay lại")
    command(deleteParkLot, parkLot_manage)

def modifyParkLot():
    xoamanhinh()
    print("Sửa thông tin bãi đỗ xe")
    parking_lot_id = input("Nhập ID bãi đỗ xe cần sửa: ")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("SELECT name, capacity FROM parking_lot WHERE parkinglotid = %s", (parking_lot_id,))
                parking_lot = cursor.fetchone()
                if parking_lot:
                    print(f"Bãi đỗ xe hiện tại: Tên: {parking_lot[0]}, Sức chứa: {parking_lot[1]}")
                    new_name = input(f"Nhập tên mới của bãi đỗ xe (nhấn Enter để giữ nguyên '{parking_lot[0]}'): ") or parking_lot[0]
                    while True:
                        try:
                            new_capacity = input(f"Nhập sức chứa mới của bãi đỗ xe (nhấn Enter để giữ nguyên '{parking_lot[1]}'): ")
                            new_capacity = int(new_capacity) if new_capacity else parking_lot[1]
                            break
                        except ValueError:
                            print("Giá trị nhập vào không hợp lệ, vui lòng nhập lại.")
                    
                    cursor.execute("UPDATE parking_lot SET name = %s, capacity = %s WHERE parkinglotid = %s", 
                                   (new_name, new_capacity, parking_lot_id))
                    conn.commit()
                    print("Cập nhật bãi đỗ xe thành công!")
                else:
                    print("Không tìm thấy bãi đỗ xe với ID đã nhập.")
            except Exception as e:
                print(f"Sửa thông tin bãi đỗ xe thất bại do xảy ra lỗi: {e}")

    print("1. Sửa thông tin bãi đỗ xe khác")
    print("2. Quay lại")
    command(modifyParkLot, parkLot_manage)

def reviewParkLot():
    xoamanhinh()
    print("Duyệt thông tin bãi đỗ xe")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("""
                    SELECT parkinglotid, name, capacity, staff.fullname
                    FROM parking_lot NATURAL JOIN staff;
                """)
                parking_lots = cursor.fetchall()
                if parking_lots:
                    current_parkinglotid = None
                    for lot in parking_lots:
                        if lot[0] != current_parkinglotid:
                            current_parkinglotid = lot[0]
                            staff_name = lot[3] if lot[3] else "Không có"
                            print(f"ID: {lot[0]}, Tên: {lot[1]}, Sức chứa: {lot[2]}, Nhân viên quản lý: {staff_name}")
                else:
                    print("Không có bãi đỗ xe nào trong cơ sở dữ liệu.")
            except Exception as e:
                print(f"Duyệt thông tin bãi đỗ xe thất bại do xảy ra lỗi: {e}")

    print("\n1. Duyệt lại")
    print("2. Quay lại")
    command(reviewParkLot, parkLot_manage)

def database_manage():
    xoamanhinh()
    print("Quản lý cơ sở dữ liệu")
    print("1. ER Model Diagram")
    print("2. SQL Query")
    print("3. Quay lại")
    command(er_model, sql_query, success_admin_login)

def er_model():
    os.system('start D:\Programming\CARPARKINGLOTPROJECT\\readme\er_graph.png')
    database_manage()

def sql_query():
    xoamanhinh()
    print("SQL Tiện Lợi")
    sqlcmd = input("SQL Command: ")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            try:
                cursor.execute(sqlcmd)
                rows = cursor.fetchall()
                if rows:
                    header = [des[0] for des in cursor.description]
                    print(header)
                    print(tabulate(rows, headers=header, tablefmt="github"))
                else: 
                    print("-> " + cursor.statusmessage)    # In các trạng thái do database trả về sau mỗi query
                conn.commit()
                print("Thành công!")
            except psycopg2.Error as e:
                print("Error: ", e)
    print("1. Thử lại")
    print("2. Quay lại")
    command(sql_query, database_manage)

def revenue_manage():
    xoamanhinh()
    print("Quản lý doanh thu")
    print("1. Thống kê doanh thu theo ngày")
    print("2. Thống kê doanh thu theo tháng")
    print("3. Thống kê doanh thu theo năm")
    print("4. Quay lại")
    command(revenue_day, revenue_month, revenue_year, success_admin_login)

def revenue_day():
    xoamanhinh()
    print("Thống kê doanh thu theo ngày")
    # default date is today
    print("Mặc định là ngày hôm nay, có thể nhập nhiều ngày khác nhau")
    dates = input("Nhập ngày (yyyy/mm/dd): ")
    if dates == "thisweek":
        dates = [datetime.now() - timedelta(days=i) for i in range(7)]
        dates = [date.strftime("%Y-%m-%d") for date in dates]
    elif dates == "thismonth":
        dates = [datetime.now() - timedelta(days=i) for i in range(30)]
        dates = [date.strftime("%Y-%m-%d") for date in dates]
    else: 
        dates = dates.split(",")  
        # Chuyển ngày về định dạng yyyy/mm/dd cho phù hơp với database1
        dates = [convert_date(date.strip()) for date in dates if re.match(date_regex, date.strip())] 
        if len(dates) == 0:
            dates = [datetime.now().strftime("%Y-%m-%d")]
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            try:
                rows = []
                for i in range(len(dates)):
                    cursor.execute("""
                    SELECT  
                            time::date "Ngày",
                            SUM(amount) "Doanh thu",
                            COUNT(transactionid) "Số lượng giao dịch"
                    FROM    transaction
                    WHERE   tranaction_type = false
                    GROUP BY time::date HAVING time::date = %s;
                    """, (dates[i],))
                    if i == 0:
                        header = [des[0] for des in cursor.description]
                    theday = cursor.fetchall()
                    if theday:
                        rows.extend(theday)
                    else:
                        rows.extend([(dates[i], 0, 0)])
                print(tabulate(rows, headers=header, tablefmt="github"))
                graph = input("Xuất đồ thị không? (1/0): ")
                if graph == "1":
                    if len(rows) > 3:
                        dates_plot = [row[0] for row in rows]
                        revenue_plot = [row[1] for row in rows]
                        plt.figure(figsize=(10, 5))
                        plt.plot(dates_plot, revenue_plot, marker='o')
                        plt.xlabel('Ngày')
                        plt.ylabel('Doanh thu')
                        plt.title('Doanh thu theo ngày')
                        plt.xticks(rotation=45)
                        plt.tight_layout()
                        plt.savefig(r"revenue\revenue_created_at_{}.png".format(datetime.now().strftime("%d-%m-%Y")))
                        plt.show()
            except psycopg2.Error as e:
                print("Error: ", e)
    print("1. Thử lại")
    print("2. Quay lại")
    command(revenue_day, revenue_manage)

def revenue_month():
    xoamanhinh()
    print("Thống kê doanh thu theo tháng")
    # default month is this month
    print("Mặc định là tháng hiện tại, có thể nhập nhiều tháng khác nhau")
    months = input("Nhập tháng (mm/yyyy): ")
    if months == "thisyear":
        months = [{'month': i + 1, 
                   'year': datetime.now().year} for i in range(datetime.now().month)]
    else:
        months = months.split(",")
        months = [month.strip().split("/") for month in months]
        months = [{"month": int(month[0]), "year": int(month[1])} for month in months if month[0].isdigit() and int(month[0]) in range(1, 13)]
        if len(months) == 0:
            months = [{"month": datetime.now().month, "year": datetime.now().year}]
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            try:
                rows = []
                for i in range(len(months)):
                    cursor.execute("""
                    SELECT  
                        date_part('year', time) "Năm",
                        date_part('month', time) "Tháng",
                        SUM(amount) "Doanh thu",
                        COUNT(transactionid) "Số lượng giao dịch"
                    FROM    transaction
                    WHERE   tranaction_type = false
                    GROUP BY date_part('year', time), date_part('month', time)
                    HAVING date_part('year', time) = %s AND date_part('month', time) = %s;
                    """, (months[i]["year"], months[i]["month"]))
                    if i == 0:
                        header = [des[0] for des in cursor.description]
                    themonth = cursor.fetchone()
                    themonth = [int(x) for x in themonth] if themonth else [months[i]["year"], months[i]["month"], 0, 0]
                    rows.extend([themonth])
                print(tabulate(rows, headers=header, tablefmt="github"))
                graph = input("Xuất đồ thị không? (1/0): ")
                if graph == "1":
                    if len(rows) > 3:
                        year_months_plot = ["{}/{}".format(row[0], row[1]) for row in rows]
                        revenue_plot = [row[3] for row in rows]
                        plt.figure(figsize=(10, 5))
                        plt.plot(year_months_plot, revenue_plot, marker='o')
                        plt.xlabel('Tháng')
                        plt.ylabel('Doanh thu')
                        plt.title('Doanh thu theo tháng')
                        plt.xticks(rotation=45)
                        plt.tight_layout()
                        plt.savefig(r"revenue\month_revenue_created_at_{}.png".format(datetime.now().strftime("%d-%m-%Y")))
                        plt.show()
            except psycopg2.Error as e:
                print("Error: ", e)
    print("1. Thử lại")
    print("2. Quay lại")
    command(revenue_month, revenue_manage)

def revenue_year():
    xoamanhinh()
    print("Doanh thu năm nay")
    # default year is this year
    year = datetime.now().strftime("%Y")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor: 
            try:
                cursor.execute("""
                SELECT  SUM(amount) "Doanh thu",
                        COUNT(transactionid) "Số lượng giao dịch"
                FROM    transaction
                WHERE   date_part('year', time) = %s and tranaction_type = false
                """, (year,))
                rows = cursor.fetchall()
                if rows:
                    header = [des[0] for des in cursor.description]
                    print(tabulate(rows, headers=header, tablefmt="github"))
                else: 
                    print("Không có giao dịch nào trong năm " + year)
            except psycopg2.Error as e:
                print("Error: ", e)
    print("1. Thử lại")
    print("2. Quay lại")
    command(revenue_year, revenue_manage)

def signup():
    xoamanhinh()
    print("1. Sinh viên đăng kí gửi xe bằng thẻ sinh viên")
    print("2. Đăng kí trở thành nhân viên nhà xe")
    print("3. Quay lại")
    command(student_signup, staff_signup, menu)

def student_signup():
    balance = 0
    xoamanhinh()
    fullname = input("Tên: ")
    mssv = input("MSSV: ")
    while not(re.match(mssv_regex, mssv)):
        xoamanhinh()
        print("Mã số sinh viên không hợp lệ! Mã số sinh viên phải bắt đầu bằng 20 và có 8 chữ số.")
        mssv = input("MSSV: ")
    password = getpass("Password: ")
    check_password = getpass("Verify Password: ")
    while password != check_password:
        xoamanhinh()
        print("Mật khẩu nhập vào không khớp. Vui lòng nhập lại")
        password = getpass("Password: ")
        check_password = getpass("Verify Password: ")
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("""INSERT INTO customer(customertype) VALUES(%s) RETURNING customerid""",('t',))
                ID = cursor.fetchone()[0]
                cursor.execute("INSERT INTO student VALUES(%s, %s, %s, %s, %s)", (ID,fullname,mssv,balance,password))
                conn.commit()
                print("Tài khoản của bạn đã đăng kí thành công!")
                print("1. Đăng nhập")
                print("2. Thoát")
                command(student_login, exit)
                return
            except psycopg2.IntegrityError as e:
                print("Tài khoản của bạn đã tồn tại.")
                print("1. Thử lại")
                print("2. Thoát")
                command(student_signup, exit)
                return


def staff_signup():
    xoamanhinh()
    fullname = input("Tên của bạn là: ")
    datebirth = input("Ngày/tháng/năm sinh: ")
    while not(re.match(date_regex, datebirth)):
        xoamanhinh()
        print("Ngày tháng năm sinh bạn nhập không hợp lệ.\nHãy nhập theo mẫu dd/mm/yyyy")
        datebirth = input("Ngày/tháng/năm sinh: ")
    email = input("Email của bạn là: ")
    while not(re.match(email_regex,email)):
        xoamanhinh()
        print("Email của bạn không hợp lệ. Hãy nhập lại")
        email = input("Email của bạn là: ")
    sender_email = host_email
    sender_password = host_password
    subject = "Xác nhận email của bạn"
    code = ''.join(random.choices('0123456789', k=4))
    body = f"Mã xác thực của bạn là: {code}."
    message = MIMEMultipart()
    message['From'] = sender_email
    message['To'] = email
    message['Subject'] = subject
    message.attach(MIMEText(body, 'plain'))
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        text = message.as_string()
        server.sendmail(sender_email, email, text)
    except Exception as e:
        print(f"Failed to send email. Error: {e}")
        print("Không thể gửi email, vui lòng kiểm tra lại địa chỉ email của bạn.")
        signup()
        return
    finally:
        server.quit()
    code_input = input("Nhập mã xác thực được gửi về email của bạn: ")
    check = 3
    if(code == code_input):
        xoamanhinh()
    else: 
        while code != code_input and check != 0:
            xoamanhinh()
            print(f"Nhập sai OTP, bạn còn {check} lần thử.")
            code_input = input("Nhập mã xác thực được gửi về email của bạn: ")
            check -= 1
        else: 
            xoamanhinh()
            print("Xác nhận OTP thất bại")
            print("1. Thử lại")
            print("2. Thoát")
            command(staff_signup,menu)
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("""INSERT INTO application(fullname, datebirth, email) 
                              VALUES(%s,%s,%s) RETURNING id""",(fullname,datebirth,email))
                print("Đăng kí thành công, vui lòng nộp CV của bạn cho chúng tôi và kiểm tra email thường xuyên!")
                conn.commit()
            except:
                print("Lỗi không thể đăng kí, vui lòng thử lại sau")
    input("Nhấn Enter để quay lại...")
    signup()

def fail_login(): 
    xoamanhinh()
    print("Bạn đã nhập sai tài khoản hoặc mật khẩu. Hãy thử lại!")
    print("1. Log in")
    print("2. Exit")
    command(login, exit) 

def logout():
    reset_all_login_info()
    menu()

menu()
