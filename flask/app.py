'''Add and list todo list'''
import os
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from flask import Flask
# from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__)


db_user = os.environ.get('POSTGRES_DB_USER')
db_pswd = os.environ.get('POSTGRES_DB_PSWD')
db_host = os.environ.get('POSTGRES_SERVICE_HOST')

# disregard warning messages
app.config['SQLAlchemy_TRACK_MODIFICATIONS'] = False
# database location and name of database (Todo)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://{0}:{1}@{2}/Todo'.format(
    db_user, db_pswd, db_host
)

# instanciate SQLAlchemy object (db) and pass in the app
db = SQLAlchemy(app)

# Create a class represent a table in the database model. The model map to a table.
class Todo(db.Model):
    '''define todo'''
    __tablename__ = "Todo"
    id = db.Column(db.Integer, primary_key=True)
    todo = db.Column(db.String(500), default='')
    days = db.Column(db.Integer, default=1)
    date_created = db.Column(db.DateTime, default=datetime.now)



# add todo items: hostname/<todo_description>/<days_before_expired>
@app.route('/<todo>/<days>')
def index(todo):
    '''add a todo item'''
    todo = Todo(todo=todo)
    days = Todo(days=days)
    db.session.add(todo)
    db.session.commit()

    return '<h1>Added new item!</h1>'


# @app.route('/<todo>')
# def get_todo(todo):
# todo = Todo.query.filter_by(todo=todo).first()

#     return f'{ todo.todo } expires in { todo.days }'


@app.route('/')
def get_todo(todo):
    '''get todo list'''

    todo = Todo.query.all()
    return '<h1>Readiness Probe Return Page!</h1>'
#    return f'{ todo.todo } expires in { todo.days } from { todo.date_created }'


if __name__ == '__main__':
    app.run()
