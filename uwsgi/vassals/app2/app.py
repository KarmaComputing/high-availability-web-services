from flask import Flask
from sqlalchemy import create_engine


app = Flask(__name__)

print("Booting app2 vassal..." * 100)

engine = create_engine(
    "mysql+pymysql://username:password@tidb.pcpink.co.uk:4000/app2?charset=utf8mb4",
    pool_pre_ping=True,
)
engine.connect()  # Verify database connection


@app.route("/")
def hello_world():
    with engine.connect() as con:
        result = con.execute("SELECT NOW()")
        for row in result:
            print(row)
        return f"hello from app2<br />Result of NOW() from database: {row}"


@app.route("/test", methods=["POST"])
def test():
    return "post recieved to app2"
