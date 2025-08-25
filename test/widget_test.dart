import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/main.dart';

void main() {
  testWidgets('Ứng dụng đố vui hiển thị tiêu đề, câu hỏi, hình ảnh và chú thích', (WidgetTester tester) async {
    await tester.pumpWidget(const QuizApp());

    expect(find.text('Đố Vui'), findsOneWidget);
    expect(find.text('11 x 11 bằng bao nhiêu?'), findsOneWidget);
    expect(find.text('Điểm: 0'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Kiểm tra trả lời đúng và hiển thị chú thích
    await tester.tap(find.text('121'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Đúng rồi!'), findsOneWidget);
    expect(find.text('11 x 11 = 121, phép nhân cơ bản.'), findsOneWidget);
  });
}