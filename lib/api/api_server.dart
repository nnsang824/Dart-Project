import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Thêm import này

class ApiServer {
  static final ApiServer _instance = ApiServer._internal();
  factory ApiServer() => _instance;
  ApiServer._internal();

  late Database _database;
  late HttpServer _server;

  static const String _serverAddress =
      '9203-101-53-36-58.ngrok-free.app'; // Forwarding  ngrok
  static const int _serverPort = 8081;

  static String get serverAddress => _serverAddress;
  static int get serverPort => _serverPort;

  Future<Response> getQuestions(Request request) async {
    final questions = await _database.query('Questions');
    print('Returning ${questions.length} questions');
    return Response.ok(
      jsonEncode(questions),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> addQuestion(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    await _database.insert('Questions', {
      'questionText': payload['questionText'],
      'imagePath': payload['imagePath'],
      'options': jsonEncode(payload['options']),
      'correctAnswerIndex': payload['correctAnswerIndex'],
      'explanation': payload['explanation'],
    });
    return Response.ok('Question added');
  }

  Future<Response> deleteQuestion(Request request) async {
    final id = int.parse(request.params['id']!);
    await _database.delete('Questions', where: 'id = ?', whereArgs: [id]);
    return Response.ok('Question deleted');
  }

  Future<void> start() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = path.join(dbPath, 'questions.db');
      print('Attempting to open database at: $dbFile');
      _database = await openDatabase(
        dbFile,
        version: 1,
        onCreate: (db, version) async {
          print('Creating database table...');
          await db.execute('''
          CREATE TABLE IF NOT EXISTS Questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            questionText TEXT NOT NULL,
            imagePath TEXT,
            options TEXT NOT NULL,
            correctAnswerIndex INTEGER NOT NULL,
            explanation TEXT
          )
        ''');
          print('Inserting initial questions...');
          await db.execute(
            'INSERT OR IGNORE INTO Questions (questionText, imagePath, options, correctAnswerIndex, explanation) VALUES',
          );
          await db.execute(
            "('11 x 11 bằng bao nhiêu?', 'assets/images/math.jpeg', '[\"111\", \"121\", \"131\", \"141\"]', 1, '11 x 11 = 121, phép nhân cơ bản.')",
          );
          await db.execute(
            "('Thủ đô của Việt Nam là gì?', 'assets/images/hanoi.jpg', '[\"Hà Nội\", \"TP.HCM\", \"Đà Nẵng\", \"Huế\"]', 0, 'Hà Nội là thủ đô của Việt Nam từ năm 1945.')",
          );
          await db.execute(
            "('Hành tinh nào gần Mặt Trời nhất?', 'assets/images/mercury.webp', '[\"Sao Hỏa\", \"Sao Thủy\", \"Sao Mộc\", \"Trái Đất\"]', 1, 'Sao Thủy (Mercury) là hành tinh gần Mặt Trời nhất, cách khoảng 58 triệu km.')",
          );
          await db.execute(
            "('Ai là tác giả của \"Truyện Kiều\"?', 'assets/images/truyen_kieu.jpeg', '[\"Nguyễn Du\", \"Hồ Xuân Hương\", \"Tố Hữu\", \"Nguyễn Bính\"]', 0, 'Nguyễn Du (1765-1820) là tác giả của \"Truyện Kiều\", tác phẩm văn học nổi tiếng Việt Nam.')",
          );
          await db.execute(
            "('2^3 bằng bao nhiêu?', 'assets/images/math.jpeg', '[\"6\", \"8\", \"12\", \"16\"]', 1, '2^3 = 2 x 2 x 2 = 8.')",
          );
          await db.execute(
            "('Nước nào tổ chức World Cup 2022?', 'assets/images/worldcup.jpeg', '[\"Brazil\", \"Qatar\", \"Pháp\", \"Argentina\"]', 1, 'Qatar là nước đầu tiên ở Trung Đông tổ chức World Cup vào năm 2022.')",
          );
          await db.execute(
            "('Nguyên tố hóa học \"O\" là gì?', 'assets/images/oxygen.webp', '[\"Oxy\", \"Vàng\", \"Sắt\", \"Nitơ\"]', 0, 'Ký hiệu \"O\" trong bảng tuần hoàn là nguyên tố Oxy, cần thiết cho sự sống.')",
          );
          await db.execute(
            "('Năm nào Việt Nam giành độc lập?', 'assets/images/1945.jpg', '[\"1945\", \"1954\", \"1975\", \"1930\"]', 0, 'Việt Nam tuyên bố độc lập vào ngày 2/9/1945 tại Quảng trường Ba Đình, Hà Nội.')",
          );
          await db.execute(
            "('Hồ lớn nhất Việt Nam là gì?', 'assets/images/ho_babe.jpeg', '[\"Hồ Gươm\", \"Hồ Ba Bể\", \"Hồ Thác Bà\", \"Hồ Dầu Tiếng\"]', 1, 'Hồ Ba Bể là hồ nước ngọt lớn nhất Việt Nam, nằm ở Bắc Kạn, với diện tích khoảng 650 ha.')",
          );
          await db.execute(
            "('Loài động vật nào lớn nhất trên Trái Đất?', 'assets/images/cavoixanh.jpg', '[\"Cá voi xanh\", \"Kiến\", \"Voi\", \"Hà mã\"]', 0, 'Cá voi xanh là động vật lớn nhất, có thể dài tới 30m và nặng 200 tấn.')",
          );
          await db.execute(
            "('Thành phố nào được gọi là \"Thành phố hoa\" của Việt Nam?', 'assets/images/dalat.jpeg', '[\"Hà Nội\", \"Đà Lạt\", \"Huế\", \"Sài Gòn\"]', 1, 'Đà Lạt được gọi là \"Thành phố hoa\" nhờ khí hậu mát mẻ và nhiều loài hoa đẹp.')",
          );
          await db.execute(
            "('Ai là nhà bác học phát minh ra bóng đèn?', 'assets/images/edison.jpg', '[\"Albert Einstein\", \"Thomas Edison\", \"Isaac Newton\", \"Nikola Tesla\"]', 1, 'Thomas Edison phát minh bóng đèn sợi đốt thực dụng vào năm 1879.')",
          );
          await db.execute(
            "('Quốc hoa của Việt Nam là gì?', 'assets/images/lotus.jpg', '[\"Hoa hồng\", \"Hoa sen\", \"Hoa mai\", \"Hoa đào\"]', 1, 'Hoa sen là quốc hoa của Việt Nam, tượng trưng cho sự thanh cao và tinh khiết.')",
          );
          await db.execute(
            "('Sông dài nhất Việt Nam là gì?', 'assets/images/songdongnai.webp', '[\"Sông Hồng\", \"Sông Cửu Long\", \"Sông Đồng Nai\", \"Sông Thu Bồn\"]', 2, 'Sông Đồng Nai là con sông nội địa dài nhất Việt Nam, với chiều dài 586 km, khởi nguồn từ cao nguyên Liangbiang (Lâm Đồng).')",
          );
          await db.execute(
            "('Hành tinh nào được gọi là \"Hành tinh đỏ\"?', 'assets/images/mars.jpg', '[\"Sao Hỏa\", \"Sao Kim\", \"Sao Mộc\", \"Sao Thổ\"]', 0, 'Sao Hỏa được gọi là \"Hành tinh đỏ\" do bề mặt chứa nhiều oxit sắt (rỉ sét).')",
          );
          await db.execute(
            "('Bộ phim nào đoạt Oscar phim hay nhất năm 2020?', 'assets/images/Parasite.jpg', '[\"Joker\", \"1917\", \"Parasite\", \"Once Upon a Time in Hollywood\"]', 2, '\"Parasite\" của đạo diễn Bong Joon-ho là phim Hàn Quốc đầu tiên đoạt Oscar Phim hay nhất năm 2020.')",
          );
          await db.execute(
            "('Chất nào chiếm phần lớn trong khí quyển Trái Đất?', 'assets/images/nitrogen.jpg', '[\"Oxy\", \"Nitơ\", \"Carbon Dioxide\", \"Hydro\"]', 1, 'Nitơ chiếm khoảng 78% khí quyển Trái Đất, Oxy chỉ chiếm 21%.')",
          );
          await db.execute(
            "('Ai là vị vua đầu tiên của nhà Nguyễn?', 'assets/images/gialong.jpeg', '[\"Gia Long\", \"Minh Mạng\", \"Thiệu Trị\", \"Tự Đức\"]', 0, 'Gia Long (Nguyễn Ánh) là vị vua đầu tiên của nhà Nguyễn, trị vì từ 1802 đến 1820.')",
          );
          await db.execute(
            "('Đỉnh núi cao nhất Việt Nam là gì?', 'assets/images/fanxipang.jpg', '[\"Phan Xi Păng\", \"Ngọc Linh\", \"Tà Chì Nhù\", \"Bạch Mộc Lương Tử\"]', 0, 'Phan Xi Păng cao 3.147m, được gọi là \"Nóc nhà Đông Dương\", nằm ở Lào Cai và Lai Châu.')",
          );
          print(
            'Database initialized with ${await db.query('Questions')} questions',
          );
        },
      );
      _server = await io.serve(
        Router()
          ..get('/questions', getQuestions)
          ..post('/questions', addQuestion)
          ..delete('/questions/<id>', deleteQuestion),
        _serverAddress,
        _serverPort,
      );
      print('API server running on http://${_serverAddress}:${_serverPort}');
    } catch (e) {
      print('Error starting API server: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _database.close();
    await _server.close();
    print('API server stopped');
  }
}
