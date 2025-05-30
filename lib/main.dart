import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日语数字朗读练习',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PracticePage(),
    );
  }
}

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  int currentNumber = 0;
  int currentQuestion = 0;
  int correctCount = 0;

  bool revealed = false;
  bool answered = false;
  bool isCorrect = false;
  bool timeUp = false;
  bool gameStarted = false;
  bool gameEnded = false;

  int countdown = 5;
  Timer? timer;

  void _generateRandomNumber() {
    currentNumber = (0 + (10000 * (1.0 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt());
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      currentQuestion = 1;
      correctCount = 0;
    });
    _startNewQuestion();
  }

  void _startNewQuestion() {
    setState(() {
      revealed = false;
      answered = false;
      isCorrect = false;
      timeUp = false;
      countdown = 5;
      _generateRandomNumber();
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        countdown--;
        if (countdown <= 0) {
          timer?.cancel();
          _revealAnswer(autoFail: true);
        }
      });
    });
  }

  void _revealAnswer({bool autoFail = false}) {
    setState(() {
      revealed = true;
      if (autoFail) {
        answered = true;
        isCorrect = false;
        timeUp = true;
      }
    });
    timer?.cancel();
  }

  void _submit(bool correct) {
    if (answered) return;
    setState(() {
      answered = true;
      isCorrect = correct;
      if (correct) correctCount++;
    });
  }

  void _nextQuestion() {
    if (currentQuestion >= 20) {
      setState(() {
        gameEnded = true;
      });
      return;
    }
    setState(() {
      currentQuestion++;
    });
    _startNewQuestion();
  }

  void _resetGame() {
    timer?.cancel();
    setState(() {
      currentQuestion = 0;
      correctCount = 0;
      gameStarted = false;
      gameEnded = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) {
      return Scaffold(
        appBar: AppBar(title: const Text('便利店レジ模拟器')),
        body: Center(
          child: ElevatedButton(
            onPressed: _startGame,
            child: const Text('点击开始'),
          ),
        ),
      );
    }

    if (gameEnded) {
      final scoreRate = (correctCount / 20 * 100).toStringAsFixed(1);
      return Scaffold(
        appBar: AppBar(title: const Text('答题结束')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎉 答题结束 🎉', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),
              Text('总得分：$correctCount / 20', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 10),
              Text('正确率：$scoreRate%', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _resetGame,
                child: const Text('重新开始'),
              ),
            ],
          ),
        ),
      );
    }

    final kana = getKana(currentNumber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('便利店レジ模拟器'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('$correctCount / $currentQuestion'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '第 $currentQuestion 题：$currentNumber',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 12),
            Text(
              revealed ? '假名读音：$kana' : '假名读音：？？？',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            if (!revealed)
              Text(
                '倒计时：$countdown 秒',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            const SizedBox(height: 16),
            if (!revealed)
              ElevatedButton(
                onPressed: _revealAnswer,
                child: const Text('点击查看读音'),
              )
            else if (!answered && !timeUp)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _submit(true),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                    ),
                    child: const Text('✔️ 正确'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _submit(false),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                    ),
                    child: const Text('❌ 错误'),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('下一题'),
              ),
          ],
        ),
      ),
    );
  }
}

// 自动生成日语假名
String getKana(int number) {
  if (number == 0) return 'ぜろ';

  final ones = ['', 'いち', 'に', 'さん', 'よん', 'ご', 'ろく', 'なな', 'はち', 'きゅう'];
  final hundreds = ['', 'ひゃく', 'にひゃく', 'さんびゃく', 'よんひゃく', 'ごひゃく', 'ろっぴゃく', 'ななひゃく', 'はっぴゃく', 'きゅうひゃく'];
  final thousands = ['', 'せん', 'にせん', 'さんぜん', 'よんせん', 'ごせん', 'ろくせん', 'ななせん', 'はっせん', 'きゅうせん'];

  int thou = number ~/ 1000;
  int hund = (number % 1000) ~/ 100;
  int ten = (number % 100) ~/ 10;
  int one = number % 10;

  final buffer = StringBuffer();

  if (thou > 0) buffer.write(thousands[thou]);
  if (hund > 0) buffer.write(hundreds[hund]);
  if (ten > 0) {
    if (ten == 1) {
      buffer.write('じゅう');
    } else {
      buffer.write('${ones[ten]}じゅう');
    }
  }
  if (one > 0) buffer.write(ones[one]);

  return buffer.toString();
}
