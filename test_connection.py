"""Checking if Python can connect to the local SQL Server """
import pyodbc

CONN_STR = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=SentinelBank;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

with pyodbc.connect(CONN_STR, timeout=5) as conn:
    row = conn.cursor().execute("SELECT DB_NAME(), @@VERSION").fetchone()
    print("Connected to database:", row[0])
    print(row[1].splitlines()[0])
