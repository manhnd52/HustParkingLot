#SMTP Gmail
# 1. Bật xác minh 2 bước
# 2. Sử dụng App Password

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Đọc địa chỉ email từ file
recipient_email = "ducquank52t1@gmail.com"

# Thông tin tài khoản Gmail của bạn
sender_email = "manha1k48@gmail.com"
sender_password = "gvva dbrf ducs syhj"

# Tạo nội dung email
subject = "Test Email"
body = "This is a test email sent from Python script. 26/5/2024"

# Thiết lập MIME
message = MIMEMultipart()
message['From'] = sender_email
message['To'] = recipient_email
message['Subject'] = subject

print(message)
input()

# Đính kèm phần nội dung vào email
message.attach(MIMEText(body, 'plain'))

for i in range(10):
    try:
        # Thiết lập kết nối với server SMTP của Gmail
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()

        # Đăng nhập vào tài khoản Gmail của bạn
        server.login(sender_email, sender_password)

        # Gửi email
        text = message.as_string()
        server.sendmail(sender_email, recipient_email, text)

        print("Email sent successfully!")

    except Exception as e:
        print(f"Failed to send email. Error: {e}")

    finally:
        # Đóng kết nối server
        server.quit()
