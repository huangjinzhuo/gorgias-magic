'''Add and list todo list'''
import os
from flask_sqlalchemy import SQLAlchemy
from flask import Flask, render_template

app = Flask(__name__)


db_name = os.environ.get('POSTGRES_DB_NAME')
db_user = os.environ.get('POSTGRES_DB_USER')
db_pswd = os.environ.get('POSTGRES_DB_PSWD')
db_host = os.environ.get('POSTGRES_SERVICE_HOST')
db_port = os.environ.get('POSTGRES_SERVICE_PORT')

# disregard warning messages
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# database location and name(sqlitedb for sqlite, or db_name for postgres). Choose one of the following two lines.
# app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///sqlitedb'
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://{0}:{1}@{2}:{3}/{4}'.format(db_user, db_pswd, db_host, db_port, db_name)

# instanciate SQLAlchemy object (db) and pass in the app. now we can use db to reference the database.
db = SQLAlchemy(app)

# Create a class represent a table in the database model. The model map to a table (Todos).
class Todos(db.Model):
    '''define todo'''
#    __tablename__ = "todos"
    id = db.Column(db.Integer, primary_key=True)
    todo = db.Column(db.String(500), default='')
    days = db.Column(db.Integer, default=1)



# add a todo item
@app.route('/<todo>/<days>')
def index(todo, days):
    '''add a todo item'''
    todo = Todos(todo=todo, days=days)         # inside Todos, left to = is name of column, right is actual data which here come from URL
    db.session.add(todo)
    db.session.commit()

    return '<h1>Added successfully!</h1>'

# get todo items. /all for all items.
@app.route('/<todo>')
def get_todos(todo):
    if todo.upper() == "ALL":
        todo_list = Todos.query.all()
    else:
        todo_list = Todos.query.filter_by(todo=todo).all()

    return render_template("display_items.html", items=todo_list)


@app.route('/')
def readiness():
    '''Readiness Probe'''

    return '<h1>Readiness Probe Return Page!</h1>'



if __name__ == '__main__':
    app.run(host='0.0.0.0')
