from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

# Set up the database
with app.app_context():
   # Store data in the context
   app.config['DEBUG'] = True
   app.config['SECRET_KEY'] = 'secret'
   app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
   db = SQLAlchemy(app)
   # Create the database tables
   db.create_all()

# Define the Task model
class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(80))
    description = db.Column(db.String(200))
    done = db.Column(db.Boolean)

    def __init__(self, title, description, done):
        self.title = title
        self.description = description
        self.done = done


@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    tasks = Task.query.all()
    return jsonify([{'id': task.id, 'title': task.title, 'description': task.description, 'done': task.done} for task in tasks])

@app.route('/api//tasks/<int:task_id>', methods=['GET'])
def get_task(task_id):
    task = Task.query.get(task_id)
    if task is None:
        return jsonify({'message': 'Task not found'}), 404
    return jsonify({'id': task.id, 'title': task.title, 'description': task.description, 'done': task.done})

@app.route('/api//tasks', methods=['POST'])
def create_task():
    title = request.json['title']
    description = request.json['description']
    done = request.json.get('done', False)
    task = Task(title, description, done)
    db.session.add(task)
    db.session.commit()
    return jsonify({'id': task.id, 'title': task.title, 'description': task.description, 'done': task.done}), 201

@app.route('/api//tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    task = Task.query.get(task_id)
    if task is None:
        return jsonify({'message': 'Task not found'}), 404
    task.title = request.json.get('title', task.title)
    task.description = request.json.get('description', task.description)
    task.done = request.json.get('done', task.done)
    db.session.commit()
    return jsonify({'id': task.id, 'title': task.title, 'description': task.description, 'done': task.done})

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    task = Task.query.get(task_id)
    if task is None:
        return json
