import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
const int kTargetScore = 0; // endless — no win condition
const int kMaxLives = 3;
const int kGridSize = 9;
const double kInitialInterval = 1200; // ms
const double kMinInterval = 250; // ms
const double kIntervalDecrement = 30; // ms per virus spawn
const int kScorePerHit = 10;

// ─────────────────────────────────────────────
// GAME STATE ENUM
// ─────────────────────────────────────────────
enum GameState { idle, playing, gameOver }

// ─────────────────────────────────────────────
// MINI GAME SCREEN
// ─────────────────────────────────────────────
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> with TickerProviderStateMixin {
  // ── State variables ──
  int skor = 0;
  int posisiVirus = -1;
  int nyawa = kMaxLives;
  GameState gameState = GameState.idle;
  double currentInterval = kInitialInterval;
  int virusCount = 0; // total virus spawned (used for speed scaling)

  // ── Timers ──
  Timer? _spawnTimer;
  Timer? _disappearTimer; // auto-disappear if not tapped in time

  // ── Animation controllers ──
  late AnimationController _virusAnimController;
  late AnimationController _hitAnimController;
  late AnimationController _missAnimController;
  late AnimationController _shakeController;

  // Which cell flashed (hit/miss feedback)
  int? _hitCell;
  int? _missCell;

  final Random _random = Random();

  // ── Colors ──
  static const Color cBg = Color(0xFF0D1B2A);
  static const Color cSurface = Color(0xFF1A2D44);
  static const Color cCell = Color(0xFF1E3A55);
  static const Color cAccent = Color(0xFF00E5A0);
  static const Color cDanger = Color(0xFFFF4D6D);
  static const Color cWarning = Color(0xFFFFD166);
  static const Color cText = Color(0xFFE8F4F8);
  static const Color cMuted = Color(0xFF7CA5C2);

  @override
  void initState() {
    super.initState();
    _virusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _hitAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _missAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _disappearTimer?.cancel();
    _virusAnimController.dispose();
    _hitAnimController.dispose();
    _missAnimController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // GAME LOGIC
  // ─────────────────────────────────────────────

  void mulaiGame() {
    setState(() {
      skor = 0;
      nyawa = kMaxLives;
      posisiVirus = -1;
      gameState = GameState.playing;
      currentInterval = kInitialInterval;
      virusCount = 0;
      _hitCell = null;
      _missCell = null;
    });
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    _spawnTimer?.cancel();
    _disappearTimer?.cancel();
    if (gameState != GameState.playing) return;

    final delay = Duration(milliseconds: currentInterval.round());
    _spawnTimer = Timer(delay, _spawnVirus);
  }

  void _spawnVirus() {
    if (gameState != GameState.playing) return;

    int next;
    do {
      next = _random.nextInt(kGridSize);
    } while (next == posisiVirus);

    virusCount++;

    // Increase speed every spawn, up to kMinInterval
    currentInterval = max(kMinInterval, kInitialInterval - (virusCount * kIntervalDecrement));

    setState(() {
      posisiVirus = next;
      _hitCell = null;
      _missCell = null;
    });

    // Auto-disappear: if user doesn't tap in time → lose a life
    final disappearAfter = Duration(milliseconds: (currentInterval * 1.2).round().clamp(200, 1400));
    _disappearTimer = Timer(disappearAfter, _virusEscaped);
  }

  void _virusEscaped() {
    if (gameState != GameState.playing || posisiVirus == -1) return;

    HapticFeedback.mediumImpact();

    setState(() {
      posisiVirus = -1;
      nyawa--;
      _missCell = null;
    });

    _shakeController.forward(from: 0);

    if (nyawa <= 0) {
      _gameOver();
    } else {
      _scheduleNextSpawn();
    }
  }

  void kotakDitekan(int idx) {
    if (gameState != GameState.playing) return;

    if (idx == posisiVirus) {
      // HIT!
      _disappearTimer?.cancel();
      HapticFeedback.lightImpact();

      setState(() {
        skor += kScorePerHit;
        posisiVirus = -1;
        _hitCell = idx;
        _missCell = null;
      });

      _hitAnimController.forward(from: 0).then((_) {
        setState(() => _hitCell = null);
      });

      _scheduleNextSpawn();
    } else {
      // MISS — tap empty cell
      HapticFeedback.selectionClick();
      setState(() {
        posisiVirus = -1;
        nyawa--;
        _missCell = idx;
      });
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _missCell = null);
      });
    }
  }

  void _gameOver() {
    _spawnTimer?.cancel();
    _disappearTimer?.cancel();
    setState(() {
      gameState = GameState.gameOver;
      posisiVirus = -1;
    });
  }

  // Speed level 1–5 for UI display
  int get speedLevel {
    if (currentInterval >= 1000) return 1;
    if (currentInterval >= 750) return 2;
    if (currentInterval >= 500) return 3;
    if (currentInterval >= 350) return 4;
    return 5;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        foregroundColor: cAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildGameBody(),
            if (gameState == GameState.idle) _buildOverlayStart(),
            if (gameState == GameState.gameOver) _buildOverlayGameOver(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBody() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildHeader(),
        const SizedBox(height: 12),
        _buildScoreboard(),
        const SizedBox(height: 8),
        _buildSpeedIndicator(),
        const SizedBox(height: 20),
        _buildGrid(),
        const SizedBox(height: 16),
        _buildLives(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Basmi Virus!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: cAccent,
            letterSpacing: 1.5,
            shadows: [Shadow(color: cAccent.withOpacity(0.4), blurRadius: 16)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ketuk virus sebelum kabur!',
          style: TextStyle(fontSize: 13, color: cMuted, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildScoreboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _scoreCard('Skor', '$skor', cAccent),
        const SizedBox(width: 16),
        _scoreCard('Nyawa', '${['', '❤️', '❤️❤️', '❤️❤️❤️'][nyawa.clamp(0, 3)]}', cDanger),
      ],
    );
  }

  Widget _scoreCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: cMuted, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cText),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator() {
    final level = speedLevel;
    final labels = ['', 'Santai', 'Sedang', 'Cepat', 'Gila!', 'MAX!!!'];
    final colors = [Colors.transparent, cAccent, cAccent, cWarning, cDanger, cDanger];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Kecepatan: ', style: TextStyle(fontSize: 12, color: cMuted)),
        ...List.generate(5, (i) {
          final active = i < level;
          return Container(
            width: 16,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: active ? colors[level] : cSurface,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          labels[level],
          style: TextStyle(fontSize: 12, color: colors[level], fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 6) * 8 * (1 - _shakeController.value);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = min(constraints.maxWidth - 32, 340.0);
          final cellSize = (gridWidth - 20) / 3; // 3 cells + 2 gaps of 10
          return SizedBox(
            width: gridWidth,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: kGridSize,
              itemBuilder: (context, idx) => _buildCell(idx, cellSize),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(int idx, double size) {
    final hasVirus = idx == posisiVirus;
    final isHit = idx == _hitCell;
    final isMiss = idx == _missCell;

    Color bgColor = cCell;
    if (isHit) bgColor = cAccent.withOpacity(0.3);
    if (isMiss) bgColor = cDanger.withOpacity(0.2);

    return GestureDetector(
      onTap: () => kotakDitekan(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasVirus
                ? cAccent.withOpacity(0.5)
                : isHit
                    ? cAccent.withOpacity(0.8)
                    : isMiss
                        ? cDanger.withOpacity(0.5)
                        : Colors.white.withOpacity(0.05),
            width: hasVirus || isHit ? 2 : 1,
          ),
          boxShadow: hasVirus
              ? [BoxShadow(color: cAccent.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
        child: Center(
          child: hasVirus
              ? AnimatedBuilder(
                  animation: _virusAnimController,
                  builder: (context, _) {
                    final scale = 1.0 + sin(_virusAnimController.value * pi) * 0.12;
                    final angle = sin(_virusAnimController.value * pi * 2) * 0.15;
                    return Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: angle,
                        child: const Text('🦠', style: TextStyle(fontSize: 40)),
                      ),
                    );
                  },
                )
              : isHit
                  ? const Text('💥', style: TextStyle(fontSize: 36))
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildLives() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Nyawa: ', style: TextStyle(fontSize: 14, color: cMuted)),
        ...List.generate(kMaxLives, (i) {
          final alive = i < nyawa;
          return AnimatedOpacity(
            opacity: alive ? 1.0 : 0.25,
            duration: const Duration(milliseconds: 300),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('❤️', style: TextStyle(fontSize: 24)),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // OVERLAYS
  // ─────────────────────────────────────────────

  Widget _buildOverlayStart() {
    return _buildOverlay(
      children: [
        const Text('🦠', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text(
          'Basmi Virus!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cAccent),
        ),
        const SizedBox(height: 12),
        Text(
          'Ketuk virus sebelum kabur.\nVirus makin lama makin cepat!\nKamu punya 3 nyawa.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: cMuted, height: 1.6),
        ),
        const SizedBox(height: 28),
        _buildStartButton('Mulai Game', mulaiGame),
      ],
    );
  }

  Widget _buildOverlayGameOver() {
    return _buildOverlay(
      children: [
        const Text('💀', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text(
          'Game Over!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cDanger),
        ),
        const SizedBox(height: 8),
        Text(
          'Semua nyawa habis!',
          style: TextStyle(fontSize: 14, color: cMuted),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cAccent.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text('Skor Akhir', style: TextStyle(fontSize: 12, color: cMuted, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                '$skor',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: cAccent),
              ),
              Text(
                'Level kecepatan: $speedLevel / 5',
                style: TextStyle(fontSize: 12, color: cMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildStartButton('Main Lagi', mulaiGame),
      ],
    );
  }

  Widget _buildOverlay({required List<Widget> children}) {
    return Container(
      color: cBg.withOpacity(0.93),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          color: cAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: cAccent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: const Text(
          'Mulai Game',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0D1B2A),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
