                        cursor.execute("UPDATE student SET balance = balance - %s WHERE mssv = %s", (price, mssv))
