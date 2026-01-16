import 'package:chunne_todo/models/task.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Box _box;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  String? content;
  String? description;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    _box = await Hive.openBox("tasks");
    _refreshTasks();
  }

  void _refreshTasks() {
    _tasks = _box.values.map((e) => Task.fromMap(e)).toList();
    _filterTasks(searchQuery ?? '');
  }

  void _filterTasks(String query) {
    _filteredTasks = _tasks.where((task) {
      final title = task.todo.toLowerCase();
      final desc = (task.description ?? '').toLowerCase();
      final q = query.toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
    setState(() {});
  }

  double _calculateProgress() {
    if (_tasks.isEmpty) return 0;
    final completed = _tasks.where((t) => t.done).length;
    return completed / _tasks.length;
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Daily Planner", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _searchBar(),
          _dashboard(), // compact progress dashboard
          Expanded(child: _taskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _displayTaskPopup(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --------------------- Search Bar ---------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search tasks...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          searchQuery = value;
          _filterTasks(value);
        },
      ),
    );
  }

  // --------------------- Compact Dashboard: Time-Based ---------------------
  Widget _dashboard() {
    final todayCompleted = _tasks.where((t) => t.done && _isToday(t.timeStamp)).length;
    final todayTotal = _tasks.where((t) => _isToday(t.timeStamp)).length;
    final weeklyCompleted = _tasks.where((t) => t.done && _isThisWeek(t.timeStamp)).length;
    final weeklyTotal = _tasks.where((t) => _isThisWeek(t.timeStamp)).length;
    final monthlyCompleted = _tasks.where((t) => t.done && _isThisMonth(t.timeStamp)).length;
    final monthlyTotal = _tasks.where((t) => _isThisMonth(t.timeStamp)).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _dashboardCard("Today", "$todayCompleted/$todayTotal", _calculatePercentage(todayCompleted, todayTotal), Colors.red),
            const SizedBox(width: 8),
            _dashboardCard("This Week", "$weeklyCompleted/$weeklyTotal", _calculatePercentage(weeklyCompleted, weeklyTotal), Colors.yellow),
            const SizedBox(width: 8),
            _dashboardCard("This Month", "$monthlyCompleted/$monthlyTotal", _calculatePercentage(monthlyCompleted, monthlyTotal), Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(String title, String value, double progress, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: Colors.grey[200],
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

// --------------------- Helpers ---------------------
  double _calculatePercentage(int completed, int total) {
    if (total == 0) return 0;
    return completed / total;
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isThisWeek(DateTime dt) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return dt.isAfter(weekStart.subtract(const Duration(seconds: 1))) && dt.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  bool _isThisMonth(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month;
  }



  // --------------------- Task List ---------------------
  Widget _taskList() {
    if (_filteredTasks.isEmpty) {
      return const Center(
        child: Text("No tasks found", style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFFFFF7E5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              task.todo,
              style: TextStyle(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                decoration: task.done ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            subtitle: Text(
              "${task.description ?? ''}\n${_formatDate(task.timeStamp)}",
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    task.done ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                    color: const Color(0xFFF97316),
                  ),
                  onPressed: () {
                    task.done = !task.done;
                    _box.putAt(_tasks.indexOf(task), task.toMap());
                    _refreshTasks();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFFF59E0B)),
                  onPressed: () => _displayTaskPopup(task: task),
                ),
              ],
            ),
            onLongPress: () => _confirmDelete(task),
          ),
        );
      },
    );
  }

  // --------------------- Delete Confirmation ---------------------
  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              _box.deleteAt(_tasks.indexOf(task));
              _refreshTasks();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // --------------------- Add/Edit Task Popup ---------------------
  void _displayTaskPopup({Task? task}) {
    content = task?.todo;
    description = task?.description;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task == null ? "Add Task" : "Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: content),
                decoration: const InputDecoration(hintText: "Task title"),
                onChanged: (value) => content = value,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: description),
                decoration: const InputDecoration(hintText: "Description"),
                onChanged: (value) => description = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(task == null ? "Add" : "Update"),
              onPressed: () {
                if (content != null && content!.trim().isNotEmpty) {
                  final newTask = Task(
                    todo: content!,
                    description: description,
                    timeStamp: task?.timeStamp ?? DateTime.now(),
                    done: task?.done ?? false,
                  );

                  if (task == null) {
                    _box.add(newTask.toMap());
                  } else {
                    _box.putAt(_tasks.indexOf(task), newTask.toMap());
                  }

                  _refreshTasks();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
