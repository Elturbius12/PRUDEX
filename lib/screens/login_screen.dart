import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/screens/home_screen.dart';
import 'package:asistente_pl/widgets/gear_painter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Engranajes ────────────────────────────────────────────────────
  late AnimationController _gearCtrl;
  double _gearProgress = 0.0;
  bool _gearsUnlocked = false;

  // ── Formulario ────────────────────────────────────────────────────
  late AnimationController _formCtrl;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _gearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _formCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formSlide = Tween(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic),
    );
    _formFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut),
    );

    // Progreso automático de engranajes
    Future.delayed(const Duration(milliseconds: 600), _startGearProgress);
  }

  void _startGearProgress() {
    if (!mounted) return;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return false;
      setState(() {
        _gearProgress = (_gearProgress + 0.008).clamp(0.0, 1.0);
        if (_gearProgress >= 1.0 && !_gearsUnlocked) {
          _gearsUnlocked = true;
          _formCtrl.forward();
        }
      });
      return _gearProgress < 1.0;
    });
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    // Simulación — Supabase se conectará aquí
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _loginAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _gearCtrl.dispose();
    _formCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.04),
              // ── Engranajes animados ─────────────────────────────
              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: _gearCtrl,
                  builder: (context, _) => CustomPaint(
                    size: const Size(280, 220),
                    painter: GearPainter(
                      rotation: _gearCtrl.value * 2 * pi,
                      progress: _gearProgress,
                      color1: AppColors.turquesa,
                      color2: AppColors.ambar,
                      color3: AppColors.azul,
                    ),
                  ),
                ),
              ),

              // ── Barra de progreso ──────────────────────────────
              if (!_gearsUnlocked) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _gearProgress,
                    minHeight: 4,
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBorder,
                    valueColor: const AlwaysStoppedAnimation(AppColors.turquesa),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparando el sistema...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],

              // ── Título ─────────────────────────────────────────
              const SizedBox(height: 20),
              Text(
                'Asistente de\nDecisiones',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Programación lineal para tu negocio',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),

              // ── Formulario (aparece con fade) ──────────────────
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _formCtrl,
                builder: (context, child) => Opacity(
                  opacity: _formFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _formSlide.value),
                    child: child,
                  ),
                ),
                child: _buildForm(isDark),
              ),

              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      children: [
        // Email
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Correo electrónico',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Contraseña
        TextField(
          controller: _passCtrl,
          obscureText: !_showPass,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Contraseña',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off : Icons.visibility,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Botón login
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Iniciar sesión'),
          ),
        ),
        const SizedBox(height: 14),

        // Entrar sin cuenta
        TextButton(
          onPressed: _loginAsGuest,
          child: Text(
            'Continuar sin cuenta',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
