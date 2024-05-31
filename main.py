import re
import psycopg2
from tabulate import tabulate
import os
from getpass import getpass
import random 
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Thiết lập thông tin kết nối
DATABASE_URL = "postgresql://aefxhjyk:mvcwwnkrihotyjymxixe@alpha.india.mkdb.sh:5432/aqatqqkl"

conn_params = {
    "host": "localhost",
    "dbname": "carPark",
    "user": "postgres",
    "password": "123456"
}

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
    command(login, signup, twentyfiveQueries)

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
                    mssv "MSSV",
                    amount "Số tiền (đồng)",
                    time "Thời gian", 
                    CASE WHEN tranaction_type THEN 'Nạp tiền' ELSE 'Gửi xe' END "Loại giao dịch"
            FROM    transaction
            WHERE   mssv = %s 
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
                print("Giao dịch thành công! Số dư trong tài khoản của bạn là " + str(cursor.fetchone()[0]) + " đồng.")
            except: 
                print("Giao dịch thất bại! Vui lòng thử lại sau")
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
                        NATURAL JOIN student
                WHERE   mssv = %s
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
                        color = input("Màu xe: ")
                        # kiểm tra xe này đẫ có trong danh sách xe từng đỗ ở bãi không?
                        vehicleId = None
                        if vehicleTypeId != 2:
                            license_plate = input("Biển số xe: ")
                            # Có thể 1 xe được nhiều sinh viên dùng chung
                            cursor.execute("SELECT vehicleId FROM now_vehicle WHERE license_plate = %s AND customerId = getCustomerId(%s) AND vehicletypeid = %s", (license_plate, mssv, vehicleTypeId))
                            vehicleId = cursor.fetchone()   # tuple chứa vehicleId
                            if vehicleId is None:
                                cursor.execute("INSERT INTO now_vehicle (customerId, vehicletypeid, license_plate, color) VALUES (getCustomerId(%s), %s, %s, %s) RETURNING vehicleId", (mssv, vehicleTypeId, license_plate, color))
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
                        print(f"Bạn hãy để xe ở chỗ {spotId}!")
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
    print("5. Quản lý giao dịch")
    print("6. Log out")
    command(student_manage, staff_manage, parkLot_manage, database_manage, transaction_manage, logout)

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

def modifyStudent():
    pass

def reviewStudent():
    pass

def staff_manage():
    xoamanhinh()
    print("Quản lý nhân viên")
    print("1. Thêm")
    print("2. Xóa")
    print("3. Sửa")
    print("4. Duyệt")
    print("5. Quay lại")
    command(addStaff, deleteStaff, modifyStaff, reviewStaff, success_admin_login)

def addStaff():
    xoamanhinh()
    print("Thêm nhân viên")
    with psycopg2.connect(**conn_params) as conn: 
        with conn.cursor() as cursor: 
            try:
                name = input("Hãy nhập tên nhân viên: ")
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
                    else: print("Bãi đỗ xe không tồn tại!")
                cursor.execute("INSERT INTO Staff(fullname, parkinglotid) VALUES(%s, %s) RETURNING staffid", (name, parkinglot))
                staffid = cursor.fetchone()[0]
                print(f"Thêm nhân viên {name} thành công!") 
                print(f"Staff ID của nhân viên là {staffid}")
                print( "Mật khẩu mặc định của nhân viên là '12345678'.")
            except:
                 print("Thêm nhân viên thất bại do xảy ra lỗi!")

    print("1. Thêm nhân viên khác")
    print("2. Quay lại")
    command(addStaff, staff_manage)

def deleteStaff():
    pass

def modifyStaff():
    pass

def reviewStaff():
    pass

def parkLot_manage():
    pass

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

def transaction_manage():
    pass

def signup():
    xoamanhinh()
    print("1. Sinh viên đăng kí gửi xe bằng thẻ sinh viên")
    print("2. Đăng kí trở thành nhân viên nhà xe")
    command(student_signup, staff_signup)

def student_signup():
    balance = 0
    xoamanhinh()
    fullname = input("Tên của bạn là: ")
    mssv = input("mssv của bạn là: ")
    while not(re.match(mssv_regex, mssv)):
        xoamanhinh()
        print("Mã số sinh viên không hợp lệ! Mã số sinh viên phải bắt đầu bằng 20 và có 8 chữ số.")
        mssv = input("mssv của bạn là: ")
    password = getpass("Mật khẩu là: ")
    check_password = getpass("Nhập lại mật khẩu: ")
    while password != check_password:
        xoamanhinh()
        print("Mật khẩu nhập vào không khớp. Vui lòng nhập lại")
        password = getpass("Mật khẩu là: ")
        check_password = getpass("Nhập lại mật khẩu: ")
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

datebirth_regex = r"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[012])/(19|20)\d\d$"
email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
def staff_signup():
    xoamanhinh()
    fullname = input("Tên của bạn là: ")
    datebirth = input("Ngày/tháng/năm sinh: ")
    while not(re.match(datebirth_regex,datebirth)):
        xoamanhinh()
        print("Ngày tháng năm sinh bạn nhập không hợp lệ.\nHãy nhập theo mẫu dd/mm/yyyy")
        datebirth = input("Ngày/tháng/năm sinh: ")
    email = input("Email của bạn là: ")
    while not(re.match(email_regex, email)):
        xoamanhinh()
        print("Email của bạn không hợp lệ. Hãy nhập lại")
        email = input("Email của bạn là: ")
    sender_email = "manha1k48@gmail.com"
    sender_password = "gvva dbrf ducs syhj"
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
    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute("""INSERT INTO application(fullname, datebirth, email) 
                              VALUES(%s,%s,%s)""", (fullname, datebirth,email))
                if code == code_input:
                    xoamanhinh()
                    print("Đăng kí thành công, hãy kiểm tra email của bạn thường xuyên.")
                    conn.commit()
                else: 
                    conn.rollback()
            except Exception:
                print("Xảy ra lỗi hệ thống khi đăng kí!")
    input("Nhấn Enter để quay lại...")
    signup()


def twentyfiveQueries():
    pass

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