class Task {
  String todo;
  String? description; // new field
  DateTime timeStamp;
  bool done;

  Task({
    required this.todo,
    this.description,
    required this.timeStamp,
    this.done = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'todo': todo,
      'description': description, // save description
      'timeStamp': timeStamp.toIso8601String(),
      'done': done,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      todo: map['todo'],
      description: map['description'], // get description
      timeStamp: DateTime.parse(map['timeStamp']),
      done: map['done'],
    );
  }
}
