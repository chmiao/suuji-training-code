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
      title: '便利店レジ模拟器',
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
    // 生成 1 到 9999 的随机数，排除 0
    currentNumber = (1 + (9999 * (1.0 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt());
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      currentQuestion = 1;
      correctCount = 0;
      gameEnded = false; // 确保重新开始时游戏结束状态为 false
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
          _revealAnswer(autoFail: true); // 时间到自动揭示答案并判错
        }
      });
    });
  }

  void _revealAnswer({bool autoFail = false}) {
    setState(() {
      revealed = true;
      if (autoFail) {
        answered = true; // 时间到也算是“回答”了，只是自动判错
        isCorrect = false;
        timeUp = true;
      }
    });
    timer?.cancel();
  }

  void _submit(bool correct) {
    if (answered) return; // 避免重复提交
    setState(() {
      answered = true;
      isCorrect = correct;
      if (correct) correctCount++;
      timer?.cancel(); // 提交答案后停止计时
    });
  }

  void _nextQuestion() {
    if (currentQuestion >= 20) {
      setState(() {
        gameEnded = true;
        gameStarted = false; // 游戏结束后，将 gameStarted 设为 false，以显示结束界面
      });
      timer?.cancel(); // 游戏结束时停止计时
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
      revealed = false;
      answered = false;
      isCorrect = false;
      timeUp = false;
      countdown = 5;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    AppBar currentAppBar;

    if (!gameStarted && !gameEnded) { // 初始启动界面
      currentAppBar = AppBar(title: const Text('便利店レジ模拟器'));
      currentBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '对日语数字发音感到苦恼？那你来做题！',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '在5秒内读出数字的日语发音，结果由你自己来评判',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 请确保 assets/baito.jpg 存在，并在 pubspec.yaml 中配置
            Image.asset('assets/baito.jpg', width: 300),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('点击开始'),
            ),
          ],
        ),
      );
    } else if (gameEnded) { // 游戏结束界面
      final scoreRate = (correctCount / 20 * 100).toStringAsFixed(1);
      currentAppBar = AppBar(title: const Text('便利店レジ模拟器'));
      currentBody = Center(
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
      );
    } else { // 游戏进行中界面
      final kana = getKana(currentNumber);
      currentAppBar = AppBar(
        title: const Text('便利店レジ模拟器'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('$correctCount / $currentQuestion'),
          ),
        ],
      );
      currentBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '第 $currentQuestion 题：$currentNumber 円',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 12),
            Text(
              revealed ? '假名读音：${kana} えん' : '假名读音：？？？',
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
                child: Text('点击查看读音 (${countdown}s)'),
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
                    child: const Text('〇 正确'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _submit(false),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                    ),
                    child: const Text('✕ 错误'),
                  ),
                ],
              )
            else if (timeUp)
              Column(
                children: [
                  const Text(
                    '时间到！判定为错误。',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: const Text('下一题'),
                  ),
                ],
              )
            else // 此处已移除多余的括号
              ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('下一题'),
              ),
          ], // 修复：这里的 Column 的闭合括号和其后的 Scaffold 的闭合括号之间多了一个额外的逗号和括号。
        ), // 这是 Column 的闭合括号
      ); // 这是 Center 的闭合括号
    } // 这是 else 块的闭合括号

    // 统一返回一个 Scaffold，并将作者信息放在 bottomNavigationBar
    return Scaffold(
      appBar: currentAppBar,
      body: currentBody,
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Powered by Chamyu & LLMs',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

// 自动生成日语假名
String getKana(int number) {
  // 由于随机数范围已调整为 1-9999，理论上不会传入 0。
  // 但为了函数的健壮性，如果传入 0 仍然可以返回 'ゼロ'。
  if (number == 0) return 'ゼロ';

  // 确保所有假名都正确，没有罗马字
  final ones = ['', 'いち', 'に', 'さん', 'よん', 'ご', 'ろく', 'なな', 'はち', 'きゅう'];
  final hundreds = ['', 'ひゃく', 'にひゃく', 'さんびゃく', 'よんひゃく', 'ごひゃく', 'ろっぴゃく', 'ななひゃく', 'はっぴゃく', 'きゅうひゃく'];
  final thousands = ['', 'せん', 'にせん', 'さんぜん', 'よんせん', 'ごせん', 'ろくせん', 'ななせん', 'はっせん', 'きゅうせん'];

  // tens 数组并没有实际被使用，这里加上并注释
  // final tens = ['', 'じゅう', 'にじゅう', 'さんじゅう', 'よんじゅう', 'ごじゅう', 'ろくじゅう', 'ななじゅう', 'はちじゅう', 'きゅうじゅう'];

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