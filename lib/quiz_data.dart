class Question {
  final String questionText;
  final String imagePath;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  Question({
    required this.questionText,
    required this.imagePath,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}

final List<Question> questions = [
  Question(
    questionText: "11 x 11 bằng bao nhiêu?",
    options: ["111", "121", "131", "141"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/math.jpeg",
    explanation: "11 x 11 = 121, phép nhân cơ bản.",
  ),
  Question(
    questionText: "Thủ đô của Việt Nam là gì?",
    options: ["Hà Nội", "TP.HCM", "Đà Nẵng", "Huế"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/hanoi.jpg",
    explanation: "Hà Nội là thủ đô của Việt Nam từ năm 1945.",
  ),
  Question(
    questionText: "Hành tinh nào gần Mặt Trời nhất?",
    options: ["Sao Hỏa", "Sao Thủy", "Sao Mộc", "Trái Đất"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/mercury.webp",
    explanation:
        "Sao Thủy (Mercury) là hành tinh gần Mặt Trời nhất, cách khoảng 58 triệu km.",
  ),
  Question(
    questionText: "Ai là tác giả của 'Truyện Kiều'?",
    options: ["Nguyễn Du", "Hồ Xuân Hương", "Tố Hữu", "Nguyễn Bính"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/truyen_kieu.jpeg",
    explanation:
        "Nguyễn Du (1765-1820) là tác giả của 'Truyện Kiều', tác phẩm văn học nổi tiếng Việt Nam.",
  ),
  Question(
    questionText: "2^3 bằng bao nhiêu?",
    options: ["6", "8", "12", "16"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/math.jpeg",
    explanation: "2^3 = 2 x 2 x 2 = 8.",
  ),
  Question(
    questionText: "Nước nào tổ chức World Cup 2022?",
    options: ["Brazil", "Qatar", "Pháp", "Argentina"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/worldcup.jpeg",
    explanation:
        "Qatar là nước đầu tiên ở Trung Đông tổ chức World Cup vào năm 2022.",
  ),
  Question(
    questionText: "Nguyên tố hóa học 'O' là gì?",
    options: ["Oxy", "Vàng", "Sắt", "Nitơ"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/oxygen.webp",
    explanation:
        "Ký hiệu 'O' trong bảng tuần hoàn là nguyên tố Oxy, cần thiết cho sự sống.",
  ),
  Question(
    questionText: "Năm nào Việt Nam giành độc lập?",
    options: ["1945", "1954", "1975", "1930"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/1945.jpg",
    explanation:
        "Việt Nam tuyên bố độc lập vào ngày 2/9/1945 tại Quảng trường Ba Đình, Hà Nội.",
  ),
  Question(
    questionText: "Hồ lớn nhất Việt Nam là gì?",
    options: ["Hồ Gươm", "Hồ Ba Bể", "Hồ Thác Bà", "Hồ Dầu Tiếng"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/ho_babe.jpeg",
    explanation:
        "Hồ Ba Bể là hồ nước ngọt lớn nhất Việt Nam, nằm ở Bắc Kạn, với diện tích khoảng 650 ha.",
  ),
  Question(
    questionText: "Loài động vật nào lớn nhất trên Trái Đất?",
    options: ["Cá voi xanh", "Kiến", "Voi", "Hà mã"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/cavoixanh.jpg",
    explanation:
        "Cá voi xanh là động vật lớn nhất, có thể dài tới 30m và nặng 200 tấn.",
  ),
  Question(
    questionText: "Thành phố nào được gọi là 'Thành phố hoa' của Việt Nam?",
    options: ["Hà Nội", "Đà Lạt", "Huế", "Sài Gòn"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/dalat.jpeg",
    explanation:
        "Đà Lạt được gọi là 'Thành phố hoa' nhờ khí hậu mát mẻ và nhiều loài hoa đẹp.",
  ),
  Question(
    questionText: "Ai là nhà bác học phát minh ra bóng đèn?",
    options: [
      "Albert Einstein",
      "Thomas Edison",
      "Isaac Newton",
      "Nikola Tesla",
    ],
    correctAnswerIndex: 1,
    imagePath: "assets/images/edison.jpg",
    explanation:
        "Thomas Edison phát minh bóng đèn sợi đốt thực dụng vào năm 1879.",
  ),
  Question(
    questionText: "Quốc hoa của Việt Nam là gì?",
    options: ["Hoa hồng", "Hoa sen", "Hoa mai", "Hoa đào"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/lotus.jpg",
    explanation:
        "Hoa sen là quốc hoa của Việt Nam, tượng trưng cho sự thanh cao và tinh khiết.",
  ),
  Question(
    questionText: "Sông dài nhất Việt Nam là gì?",
    options: ["Sông Hồng", "Sông Cửu Long", "Sông Đồng Nai", "Sông Thu Bồn"],
    correctAnswerIndex: 2,
    imagePath: "assets/images/songdongnai.webp",
    explanation:
        "Sông Đồng Nai là con sông nội địa dài nhất Việt Nam, với chiều dài 586 km, khởi nguồn từ cao nguyên Liangbiang (Lâm Đồng).",
  ),
  Question(
    questionText: "Hành tinh nào được gọi là 'Hành tinh đỏ'?",
    options: ["Sao Hỏa", "Sao Kim", "Sao Mộc", "Sao Thổ"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/mars.jpg",
    explanation:
        "Sao Hỏa được gọi là 'Hành tinh đỏ' do bề mặt chứa nhiều oxit sắt (rỉ sét).",
  ),
  Question(
    questionText: "Bộ phim nào đoạt Oscar phim hay nhất năm 2020?",
    options: ["Joker", "1917", "Parasite", "Once Upon a Time in Hollywood"],
    correctAnswerIndex: 2,
    imagePath: "assets/images/Parasite.jpg",
    explanation:
        "'Parasite' của đạo diễn Bong Joon-ho là phim Hàn Quốc đầu tiên đoạt Oscar Phim hay nhất năm 2020.",
  ),
  Question(
    questionText: "Chất nào chiếm phần lớn trong khí quyển Trái Đất?",
    options: ["Oxy", "Nitơ", "Carbon Dioxide", "Hydro"],
    correctAnswerIndex: 1,
    imagePath: "assets/images/nitrogen.jpg",
    explanation: "Nitơ chiếm khoảng 78% khí quyển Trái Đất, Oxy chỉ chiếm 21%.",
  ),
  Question(
    questionText: "Ai là vị vua đầu tiên của nhà Nguyễn?",
    options: ["Gia Long", "Minh Mạng", "Thiệu Trị", "Tự Đức"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/gialong.jpeg",
    explanation:
        "Gia Long (Nguyễn Ánh) là vị vua đầu tiên của nhà Nguyễn, trị vì từ 1802 đến 1820.",
  ),
  Question(
    questionText: "Đỉnh núi cao nhất Việt Nam là gì?",
    options: ["Phan Xi Păng", "Ngọc Linh", "Tà Chì Nhù", "Bạch Mộc Lương Tử"],
    correctAnswerIndex: 0,
    imagePath: "assets/images/fanxipang.jpg",
    explanation:
        "Phan Xi Păng cao 3.147m, được gọi là 'Nóc nhà Đông Dương', nằm ở Lào Cai và Lai Châu.",
  ),
];
