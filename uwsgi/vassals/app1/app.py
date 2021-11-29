from flask import Flask
from sqlalchemy import create_engine


app = Flask(__name__)

print("Booting app1 vassal..." * 100)

# engine = create_engine(
#    "mysql+pymysql://root:afloatunknown@tidb.example.co.uk:4000/app1?charset=utf8mb4",
#    pool_pre_ping=True,
# )
# engine.connect()  # Verify database connection


@app.route("/health")
def healthcheck():
    return "healthy"


@app.route("/")
def hello_world():
    #    with engine.connect() as con:
    #        result = con.execute("SELECT NOW()")
    #        for row in result:
    #            print(row)
    #        return f"hello from app1<br />Result of NOW() from database: {row}"
    return "hello app1"


@app.route("/test", methods=["POST"])
def test():
    return "post recieved to app1"
