import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_application_2/question.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:math';
import 'api/api_server.dart';

void main() async {
  // Đảm bảo khởi tạo các widget binding
  WidgetsFlutterBinding.ensureInitialized();
  print('Starting application initialization at ${DateTime.now()}...');

  // Khởi tạo databaseFactory cho sqflite_common_ffi (dùng cho web/desktop)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('Initialized sqflite_ffi for desktop/web successfully.');
    } catch (e) {
      print('Error initializing sqflite_ffi: $e');
    }
  } else {
    print('Using native sqflite for mobile platforms.');
  }

  // Khởi tạo instance của API server
  final apiServer = ApiServer();
  bool serverStarted = false;

  // Thử khởi động server API
  try {
    print('Attempting to start API server...');
    await apiServer.start();
    print(
      'API server started successfully on http://${ApiServer.serverAddress}:${ApiServer.serverPort}',
    );
    serverStarted = true;
  } catch (e) {
    print('Failed to start API server, using fallback data: $e');
    serverStarted = false;
    await _initializeFallbackData();
  }

  // Khởi chạy ứng dụng Flutter
  print('Running Flutter app...');
  runApp(const QuizApp());

  // Đóng server khi ứng dụng kết thúc (nếu đã khởi động)
  if (serverStarted) {
    await apiServer.stop();
    print('API server stopped.');
  }
}

// Hàm khởi tạo dữ liệu fallback nếu server thất bại
Future<void> _initializeFallbackData() async {
  try {
    final db = await QuizScreenState().database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Questions'),
    );
    if (count == 0) {
      print('Database is empty, inserting fallback questions...');
      for (var question in questions) {
        await db.insert('Questions', {
          'questionText': question.questionText,
          'imagePath': question.imagePath,
          'options': jsonEncode(question.options),
          'correctAnswerIndex': question.correctAnswerIndex,
          'explanation': question.explanation,
        });
      }
      print('Inserted ${questions.length} fallback questions into database.');
    } else {
      print(
        'Database already contains $count questions, skipping fallback insertion.',
      );
    }
  } catch (e) {
    print('Error initializing fallback data: $e');
  }
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;

  Future<Database> get database async {
    return QuizScreenState().database;
  }

  @override
  void initState() {
    super.initState();
    print('HomeScreen initializing, fetching questions...');
    _fetchQuestionsFromAPI();
    _initializeDatabaseWithFallback();
  }

  Future<void> _initializeDatabaseWithFallback() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Questions'),
    );
    if (count == 0) {
      print('Database is empty, inserting fallback questions...');
      for (var question in questions) {
        await db.insert('Questions', {
          'questionText': question.questionText,
          'imagePath': question.imagePath,
          'options': jsonEncode(question.options),
          'correctAnswerIndex': question.correctAnswerIndex,
          'explanation': question.explanation,
        });
      }
      print('Inserted ${questions.length} fallback questions.');
    }
  }

  Future<void> _fetchQuestionsFromAPI() async {
    try {
      print(
        'Fetching questions from http://${ApiServer.serverAddress}:${ApiServer.serverPort}/questions...',
      );
      final response = await http
          .get(
            Uri.parse(
              'http://${ApiServer.serverAddress}:${ApiServer.serverPort}/questions',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Fetched ${data.length} questions: $data');
      } else {
        throw Exception(
          'Failed to load questions. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  void _showAdminLoginDialog(BuildContext context) {
    String password = '';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đăng nhập Admin'),
            content: TextField(
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
              onChanged: (value) => password = value,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (password == 'admin123') {
                    setState(() => _isAdmin = true);
                    Navigator.of(context).pop();
                    _showDeleteQuestionDialog(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu sai!')),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
            ],
          ),
    );
  }

  void _showDeleteQuestionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Xóa câu hỏi'),
                  content: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8.0),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: database.then((db) {
                          print('Querying database for questions...');
                          return db.query('Questions');
                        }),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError || !snapshot.hasData) {
                            print(
                              'Error loading questions in delete dialog: ${snapshot.error}',
                            );
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Không tải được danh sách câu hỏi.'),
                            );
                          }
                          final questions = snapshot.data!;
                          print(
                            'Loaded ${questions.length} questions for deletion',
                          );
                          if (questions.isEmpty)
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Không có câu hỏi để xóa.'),
                            );
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                questions.map((question) {
                                  return ListTile(
                                    title: Text(question['questionText']),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        try {
                                          final response = await http
                                              .delete(
                                                Uri.parse(
                                                  'http://${ApiServer.serverAddress}:${ApiServer.serverPort}/questions/${question['id']}',
                                                ),
                                              )
                                              .timeout(
                                                const Duration(seconds: 5),
                                              );
                                          if (response.statusCode == 200) {
                                            print(
                                              'Deleted question with id: ${question['id']} from server',
                                            );
                                            await database.then(
                                              (db) => db.delete(
                                                'Questions',
                                                where: 'id = ?',
                                                whereArgs: [question['id']],
                                              ),
                                            );
                                            print(
                                              'Deleted question with id: ${question['id']} from local database',
                                            );
                                            setState(() {});
                                          } else {
                                            print(
                                              'Failed to delete question, status code: ${response.statusCode}',
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Xóa thất bại, mã lỗi: ${response.statusCode}',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          print('Error deleting question: $e');
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Không thể kết nối tới server để xóa. Vui lòng kiểm tra kết nối hoặc khởi động server.',
                                              ),
                                            ),
                                          );
                                          // Rollback xóa cục bộ nếu server thất bại
                                          // (Tùy chọn, có thể bỏ qua nếu không muốn rollback)
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF80D8FF), Color(0xFFA7FFEB), Color(0xFFF8BBD0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chào mừng bạn đến với trò chơi Đố Vui!\nHãy thử sức với các câu hỏi thú vị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizScreen(),
                        ),
                      ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Bắt đầu', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 20),
                if (_isAdmin)
                  ElevatedButton(
                    onPressed: () => _showDeleteQuestionDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xóa câu hỏi',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _showAdminLoginDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập Admin',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int score = 0;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  int highScore = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  int? selectedIndex;
  bool showExplanation = false;
  bool isMusicPlaying = true;
  List<int>? _questionIndices;
  int _currentIndexInShuffle = 0;
  List<Question> _allQuestions = [];
  bool _isLoading = true;

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'questions.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE Questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          questionText TEXT NOT NULL,
          imagePath TEXT,
          options TEXT NOT NULL,
          correctAnswerIndex INTEGER NOT NULL,
          explanation TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE Scores (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          highScore INTEGER
        )
      ''');
        await db.insert('Scores', {'highScore': 0});
      },
    );
  }

  @override
  void initState() {
    super.initState();
    print('QuizScreen initializing...');
    _loadHighScore();
    _playBackgroundMusic();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _fetchQuestionsFromAPI();
  }

  Future<void> _fetchQuestionsFromAPI() async {
    try {
      print('Fetching questions from API...');
      final response = await http
          .get(
            Uri.parse(
              'http://${ApiServer.serverAddress}:${ApiServer.serverPort}/questions',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Fetched ${data.length} questions: $data');
        final apiQuestions =
            data
                .map(
                  (json) => Question(
                    questionText: json['questionText'] ?? 'No question',
                    imagePath: json['imagePath'] ?? 'assets/images/default.jpg',
                    options:
                        json['options'] != null
                            ? List<String>.from(jsonDecode(json['options']))
                            : ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
                    correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
                    explanation: json['explanation'] ?? 'No explanation',
                  ),
                )
                .toList();

        final db = await database;
        await db.delete('Questions');
        for (var question in apiQuestions) {
          await db.insert('Questions', {
            'questionText': question.questionText,
            'imagePath': question.imagePath,
            'options': jsonEncode(question.options),
            'correctAnswerIndex': question.correctAnswerIndex,
            'explanation': question.explanation,
          });
        }

        final List<Map<String, dynamic>> storedQuestions = await db.query(
          'Questions',
        );
        print('Stored questions count: ${storedQuestions.length}');
        setState(() {
          _allQuestions =
              storedQuestions
                  .map(
                    (map) => Question(
                      questionText: map['questionText'],
                      imagePath: map['imagePath'],
                      options: List<String>.from(jsonDecode(map['options'])),
                      correctAnswerIndex: map['correctAnswerIndex'],
                      explanation: map['explanation'],
                    ),
                  )
                  .toList();
          _questionIndices =
              (_allQuestions.isNotEmpty)
                  ? (List<int>.generate(_allQuestions.length, (i) => i)
                    ..shuffle()).take(10).toList()
                  : <int>[];
          _currentIndexInShuffle = 0;
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load questions. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching questions: $e');
      setState(() {
        _isLoading = false;
        _allQuestions = questions;
        _questionIndices =
            (_allQuestions.isNotEmpty)
                ? (List<int>.generate(_allQuestions.length, (i) => i)
                  ..shuffle()).take(10).toList()
                : <int>[];
        print(
          'Fallback to ${_allQuestions.length} questions from question.dart, using ${_questionIndices?.length ?? 0} random',
        );
      });
    }
  }

  Future<void> _loadHighScore() async {
    final db = await database;
    final List<Map<String, dynamic>> scores = await db.query('Scores');
    if (scores.isNotEmpty) {
      setState(() => highScore = scores.first['highScore']);
    }
  }

  Future<void> _saveHighScore() async {
    final db = await database;
    await db.update(
      'Scores',
      {'highScore': highScore},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _backgroundPlayer.setSource(
        AssetSource('sounds/background_music.mp3'),
      );
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.resume();
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  void _toggleMusic() {
    setState(() {
      isMusicPlaying = !isMusicPlaying;
      if (isMusicPlaying)
        _backgroundPlayer.resume();
      else
        _backgroundPlayer.pause();
    });
  }

  void _showAddQuestionDialog(BuildContext context) {
    String questionText = '', imagePath = '', explanation = '';
    List<String> options = ['', '', '', ''];
    int correctAnswerIndex = 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thêm câu hỏi mới'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Câu hỏi'),
                      onChanged: (value) => questionText = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn hình ảnh',
                      ),
                      onChanged: (value) => imagePath = value,
                    ),
                    ...List.generate(
                      4,
                      (index) => TextField(
                        decoration: InputDecoration(
                          labelText: 'Lựa chọn ${index + 1}',
                        ),
                        onChanged: (value) => options[index] = value,
                      ),
                    ),
                    DropdownButton<int>(
                      value: correctAnswerIndex,
                      items: List.generate(
                        4,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text('Lựa chọn ${index + 1}'),
                        ),
                      ),
                      onChanged:
                          (value) =>
                              setState(() => correctAnswerIndex = value!),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Giải thích',
                      ),
                      onChanged: (value) => explanation = value,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final db = await database;
                  await db.insert('Questions', {
                    'questionText': questionText,
                    'imagePath': imagePath,
                    'options': jsonEncode(options),
                    'correctAnswerIndex': correctAnswerIndex,
                    'explanation': explanation,
                  });
                  final List<Map<String, dynamic>> storedQuestions = await db
                      .query('Questions');
                  setState(() {
                    _allQuestions =
                        storedQuestions
                            .map(
                              (map) => Question(
                                questionText: map['questionText'],
                                imagePath: map['imagePath'],
                                options: List<String>.from(
                                  jsonDecode(map['options']),
                                ),
                                correctAnswerIndex: map['correctAnswerIndex'],
                                explanation: map['explanation'],
                              ),
                            )
                            .toList();
                    _questionIndices =
                        (_allQuestions.isNotEmpty)
                            ? (List<int>.generate(
                              _allQuestions.length,
                              (i) => i,
                            )..shuffle()).take(10).toList()
                            : <int>[];
                    _currentIndexInShuffle = 0;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Thêm'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    super.dispose();
  }

  void checkAnswer(BuildContext context, int index) async {
    setState(() {
      selectedIndex = index;
      showExplanation = false;
    });

    bool isCorrect =
        index ==
        _allQuestions[_questionIndices![_currentIndexInShuffle]]
            .correctAnswerIndex;
    if (isCorrect) {
      score++;
      correctAnswers++;
      try {
        await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
      } catch (e) {
        print('Error playing correct sound: $e');
      }
      setState(() => showExplanation = true);
    } else {
      incorrectAnswers++;
      try {
        await _audioPlayer.play(AssetSource('sounds/incorrect.mp3'));
      } catch (e) {
        print('Error playing incorrect sound: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? 'Đúng rồi!' : 'Sai rồi!'),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      selectedIndex = null;
      showExplanation = false;
      print(
        'Debug - Correct: $correctAnswers, Incorrect: $incorrectAnswers, Total Questions: ${_questionIndices?.length}',
      );
      if (_questionIndices != null &&
          _currentIndexInShuffle == _questionIndices!.length - 1) {
        _saveHighScore();
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Kết thúc!'),
                content: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Điểm của bạn: $score/${_questionIndices!.length}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Điểm cao nhất: $highScore/${_questionIndices!.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Thống kê:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 250,
                          width: double.maxFinite,
                          child: chart(),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndexInShuffle = 0;
                        score = 0;
                        correctAnswers = 0;
                        incorrectAnswers = 0;
                        selectedIndex = null;
                        showExplanation = false;
                        _questionIndices =
                            (_allQuestions.isNotEmpty)
                                ? (List<int>.generate(
                                  _allQuestions.length,
                                  (i) => i,
                                )..shuffle()).take(10).toList()
                                : <int>[];
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Chơi lại',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        ),
                    child: const Text(
                      'Quay về trang chủ',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
        );
      } else if (_questionIndices != null &&
          _currentIndexInShuffle < _questionIndices!.length - 1) {
        _currentIndexInShuffle++;
        _controller.reset();
        _controller.forward();
      } else {
        print('Error: Index out of range or no more questions');
      }
    });
  }

  Widget chart() {
    print(
      'Chart Data - Correct: $correctAnswers, Incorrect: $incorrectAnswers, Total: ${_questionIndices?.length ?? 0}',
    );
    if (_questionIndices == null || _questionIndices!.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu để hiển thị thống kê.'),
      );
    }
    final totalQuestions = _questionIndices!.length.toDouble();
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: correctAnswers.toDouble(),
                color: Colors.green,
                width: 20,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: totalQuestions,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: incorrectAnswers.toDouble(),
                color: Colors.red,
                width: 20,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: totalQuestions,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Đúng');
                  case 1:
                    return const Text('Sai');
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (totalQuestions / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.grey,
            getTooltipItem:
                (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '${rod.toY.round()} câu',
                  const TextStyle(color: Colors.white),
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_questionIndices == null || _allQuestions.isEmpty)
      return const Center(child: Text('Không có câu hỏi để hiển thị.'));
    final question = _allQuestions[_questionIndices![_currentIndexInShuffle]];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF80D8FF), Color(0xFFA7FFEB), Color(0xFFF8BBD0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đố Vui',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _scaleAnimation,
                                    builder:
                                        (context, child) => Transform.scale(
                                          scale: _scaleAnimation.value,
                                          child: child,
                                        ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          question.imagePath,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            BuildContext context,
                                            Object error,
                                            StackTrace? stackTrace,
                                          ) {
                                            print('Image load error: $error');
                                            return Container(
                                              height: 150,
                                              color: Colors.grey,
                                              child: const Center(
                                                child: Text(
                                                  'Hình ảnh không tải được',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    question.questionText,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (showExplanation) ...[
                          const SizedBox(height: 10),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color: Colors.green.withOpacity(0.1),
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 100,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  child: Text(
                                    question.explanation,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ...question.options.asMap().entries.map((entry) {
                          int index = entry.key;
                          String option = entry.value;
                          Color buttonColor = Colors.white;
                          if (selectedIndex != null) {
                            if (index ==
                                _allQuestions[_questionIndices![_currentIndexInShuffle]]
                                    .correctAnswerIndex) {
                              buttonColor = Colors.green.withAlpha(200);
                            } else if (index == selectedIndex &&
                                index !=
                                    _allQuestions[_questionIndices![_currentIndexInShuffle]]
                                        .correctAnswerIndex) {
                              buttonColor = Colors.red.withAlpha(200);
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: AnimatedScale(
                              scale: selectedIndex == index ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: ElevatedButton(
                                onPressed:
                                    selectedIndex == null
                                        ? () => checkAnswer(context, index)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.black,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        buttonColor,
                                        buttonColor.withAlpha(204),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Center(
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Điểm: $score',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 120,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          child: LinearProgressIndicator(
                            value:
                                _questionIndices != null
                                    ? (_currentIndexInShuffle + 1) /
                                        _questionIndices!.length
                                    : 0.0,
                            backgroundColor: Colors.transparent,
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isMusicPlaying
                                  ? Icons.music_note
                                  : Icons.music_off,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            onPressed: _toggleMusic,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentIndexInShuffle = 0;
                                score = 0;
                                correctAnswers = 0;
                                incorrectAnswers = 0;
                                selectedIndex = null;
                                showExplanation = false;
                                _questionIndices =
                                    (_allQuestions.isNotEmpty)
                                        ? (List<int>.generate(
                                          _allQuestions.length,
                                          (i) => i,
                                        )..shuffle()).take(10).toList()
                                        : <int>[];
                              });
                              _controller.reset();
                              _controller.forward();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            onPressed: () => _showAddQuestionDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
