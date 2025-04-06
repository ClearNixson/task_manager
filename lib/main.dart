import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    if (user != null) {
      return TaskListScreen();
    } else {
      return LoginScreen();
    }
  }
}

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result.user;
    } catch (e) {
      print("Sign in error: $e");
      return null;
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result.user;
    } catch (e) {
      print("Sign up error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Login'),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = await auth.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Sign Up'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? dateTime;
  final List<SubTask>? subTasks;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dateTime,
    this.subTasks,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      dateTime: data['dateTime']?.toDate(),
      subTasks: data['subTasks'] != null
          ? (data['subTasks'] as List).map((e) => SubTask.fromMap(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'dateTime': dateTime,
      'subTasks': subTasks?.map((e) => e.toMap()).toList(),
    };
  }
}

class SubTask {
  final String title;
  final String timeRange;
  bool isCompleted;

  SubTask({
    required this.title,
    required this.timeRange,
    this.isCompleted = false,
  });

  factory SubTask.fromMap(Map data) {
    return SubTask(
      title: data['title'] ?? '',
      timeRange: data['timeRange'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timeRange': timeRange,
      'isCompleted': isCompleted,
    };
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _taskController = TextEditingController();
  final _subTaskController = TextEditingController();
  final _timeRangeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _taskController.dispose();
    _subTaskController.dispose();
    _timeRangeController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_taskController.text.isEmpty) return;

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    final task = Task(
      id: '', // Firestore will generate ID
      title: _taskController.text,
      dateTime: _selectedDate,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .add(task.toFirestore());

    _taskController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  Future<void> _addSubTask(String taskId, List<SubTask> existingSubTasks) async {
    if (_subTaskController.text.isEmpty || 
        _timeRangeController.text.isEmpty) return;

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    final newSubTask = SubTask(
      title: _subTaskController.text,
      timeRange: _timeRangeController.text,
    );

    final updatedSubTasks = [...?existingSubTasks, newSubTask];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
          'subTasks': updatedSubTasks.map((e) => e.toMap()).toList(),
        });

    _subTaskController.clear();
    _timeRangeController.clear();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(task.id)
        .update({'isCompleted': !task.isCompleted});
  }

  Future<void> _toggleSubTaskCompletion(
      String taskId, int subTaskIndex, bool currentStatus) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId);

    final doc = await docRef.get();
    final data = doc.data() as Map;
    final subTasks = (data['subTasks'] as List)
        .map((e) => SubTask.fromMap(e))
        .toList();

    subTasks[subTaskIndex].isCompleted = !currentStatus;

    await docRef.update({
      'subTasks': subTasks.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> _deleteTask(String taskId) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Future<void> _deleteSubTask(String taskId, int subTaskIndex) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId);

    final doc = await docRef.get();
    final data = doc.data() as Map;
    final subTasks = (data['subTasks'] as List)
        .map((e) => SubTask.fromMap(e))
        .toList();

    subTasks.removeAt(subTaskIndex);

    await docRef.update({
      'subTasks': subTasks.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    final pickedStartTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedStartTime == null) return;

    final pickedEndTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: pickedStartTime.hour + 1,
        minute: pickedStartTime.minute,
      ),
    );
    if (pickedEndTime == null) return;

    setState(() {
      _startTime = pickedStartTime;
      _endTime = pickedEndTime;
      _timeRangeController.text =
          '${_startTime!.format(context)} - ${_endTime!.format(context)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please sign in'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          decoration: const InputDecoration(
                            labelText: 'Add a new task',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Selected date: ${DateFormat('MMM d, y').format(_selectedDate!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add Task'),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('tasks')
                        .orderBy('dateTime')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data!.docs
                          .map((doc) => Task.fromFirestore(doc))
                          .toList();

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Checkbox(
                                    value: task.isCompleted,
                                    onChanged: (_) =>
                                        _toggleTaskCompletion(task),
                                  ),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteTask(task.id),
                                  ),
                                ],
                              ),
                              subtitle: task.dateTime != null
                                  ? Text(
                                      DateFormat('MMM d, y').format(task.dateTime!),
                                    )
                                  : null,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Text('Sub-tasks:'),
                                      if (task.subTasks != null)
                                        ...task.subTasks!.asMap().entries.map(
                                              (entry) => ListTile(
                                                leading: Checkbox(
                                                  value: entry.value.isCompleted,
                                                  onChanged: (_) =>
                                                      _toggleSubTaskCompletion(
                                                    task.id,
                                                    entry.key,
                                                    entry.value.isCompleted,
                                                  ),
                                                ),
                                                title: Text(entry.value.title),
                                                subtitle:
                                                    Text(entry.value.timeRange),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete),
                                                  onPressed: () =>
                                                      _deleteSubTask(
                                                    task.id,
                                                    entry.key,
                                                  ),
                                                ),
                                              ),
                                            ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _subTaskController,
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Sub-task',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.access_time),
                                            onPressed: () =>
                                                _selectTimeRange(context),
                                          ),
                                        ],
                                      ),
                                      if (_timeRangeController.text.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Text(
                                            'Time: ${_timeRangeController.text}',
                                          ),
                                        ),
                                      ElevatedButton(
                                        onPressed: () => _addSubTask(
                                          task.id,
                                          task.subTasks ?? [],
                                        ),
                                        child: const Text('Add Sub-task'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}