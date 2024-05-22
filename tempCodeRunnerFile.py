print("Chọn loại xe: ")
                cursor.execute("SELECT DISTINCT vehicletypeid, name, size FROM vehicle_type ORDER BY vehicletypeid ASC")
                rows = {row[0]: (row[1], row[2]) for row in cursor.fetchall()}
                for i, row in rows.items():
                    print(f"{i}. {row}")