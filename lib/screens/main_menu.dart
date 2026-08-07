import 'package:flutter/material.dart';
import 'game_screen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF0A2E6B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Title with golden shield
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.casino_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'DOMINO',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '2 vs 2 TEAM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E2600),
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Buttons
              _buildButton(
                context,
                icon: Icons.play_arrow_rounded,
                label: 'START GAME',
                gradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                },
              ),
              const SizedBox(height: 16),
              _buildButton(
                context,
                icon: Icons.leaderboard_rounded,
                label: 'LEADERBOARD',
                gradient: const [Color(0xFFFF9800), Color(0xFFE65100)],
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildButton(
                context,
                icon: Icons.settings_rounded,
                label: 'SETTINGS',
                gradient: const [Color(0xFF78909C), Color(0xFF455A64)],
                onTap: () {},
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required IconData icon, required String label, required List<Color> gradient, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
