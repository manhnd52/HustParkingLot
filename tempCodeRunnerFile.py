from datetime import datetime, timedelta
months = [{'month': i + 1, 
           'year': datetime.now().year} 
           for i in range(datetime.now().month)]
print(months)