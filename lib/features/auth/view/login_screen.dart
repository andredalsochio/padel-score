import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final AnimationController _bgController;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    // Intro animations (fade + slide)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    ));
    _introController.forward();

    // Background ambiance animation (slow, subtle)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Se já autenticado, navegar para home de forma suave
      if (authVm.isAuthenticated) {
        GoRouter.of(context).go('/home');
      }
      // Exibe erro como snackbar conciso
      final err = authVm.errorMessage;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
        );
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final cardMaxWidth = isWide ? 520.0 : constraints.maxWidth * 0.92;

          return Stack(
            children: [
              // Animated gradient + ambient bubbles
              AnimatedBuilder(
                animation: _bgAnim,
                builder: (context, _) {
                  final t = _bgAnim.value;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.lerp(
                            Alignment.topLeft, Alignment.bottomLeft, t)!,
                        end: Alignment.lerp(
                            Alignment.bottomRight, Alignment.topRight, t)!,
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.25),
                          colorScheme.secondaryContainer.withValues(alpha: 0.20),
                          colorScheme.tertiaryContainer.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Ambient moving blurred bubbles
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _bgAnim,
                  builder: (context, _) {
                    final t = _bgAnim.value;
                    return Stack(
                      children: [
                        _BlurBubble(
                          color: colorScheme.primary.withValues(alpha: 0.20),
                          size: isWide ? 220 : 160,
                          alignment: Alignment.lerp(
                              const Alignment(-0.8, -0.6),
                              const Alignment(-0.6, -0.4),
                              t)!,
                        ),
                        _BlurBubble(
                          color: colorScheme.secondary.withValues(alpha: 0.18),
                          size: isWide ? 180 : 140,
                          alignment: Alignment.lerp(
                              const Alignment(0.7, -0.5),
                              const Alignment(0.6, -0.3),
                              1 - t)!,
                        ),
                        _BlurBubble(
                          color: colorScheme.tertiary.withValues(alpha: 0.16),
                          size: isWide ? 200 : 150,
                          alignment: Alignment.lerp(
                              const Alignment(0.4, 0.7),
                              const Alignment(0.6, 0.6),
                              t)!,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Centered glass card with content
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: _GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 28,
                              horizontal: 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Logo + title
                                Icon(
                                  Icons.sports_tennis,
                                  size: isWide ? 104 : 84,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Padel App',
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Torneios, rankings e partidas com elegância.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                _EmailAuthForm(loading: authVm.isLoading),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmailAuthForm extends StatefulWidget {
  const _EmailAuthForm({required this.loading});
  final bool loading;

  @override
  State<_EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<_EmailAuthForm> {
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  bool _isRegister = false;
  bool _loginObscure = true;
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Informe seu e‑mail';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (!ok) return 'E‑mail inválido';
    return null;
  }

  String? _passwordValidator(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Informe sua senha';
    if (value.length < 6) return 'Mínimo de 6 caracteres';
    return null;
  }

  InputDecoration _decoration(BuildContext context, String label, {Widget? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: scheme.surface.withValues(alpha: 0.75),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          crossFadeState:
              _isRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
          sizeCurve: Curves.easeOutCubic,
          firstChild: Form(
            key: _loginFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _loginEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _emailValidator,
                  decoration: _decoration(context, 'E‑mail'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _loginPassCtrl,
                  obscureText: _loginObscure,
                  textInputAction: TextInputAction.done,
                  validator: _passwordValidator,
                  decoration: _decoration(
                    context,
                    'Senha',
                    suffix: IconButton(
                      icon: Icon(_loginObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _loginObscure = !_loginObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: widget.loading
                        ? null
                        : () async {
                            if (_loginFormKey.currentState?.validate() ?? false) {
                              await authVm.signInWithPassword(
                                _loginEmailCtrl.text.trim(),
                                _loginPassCtrl.text,
                              );
                            }
                          },
                    child: widget.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Login',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
          secondChild: Form(
            key: _regFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _regEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _emailValidator,
                  decoration: _decoration(context, 'E‑mail'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regPassCtrl,
                  obscureText: _regObscure,
                  textInputAction: TextInputAction.next,
                  validator: _passwordValidator,
                  decoration: _decoration(
                    context,
                    'Senha',
                    suffix: IconButton(
                      icon: Icon(_regObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _regObscure = !_regObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regConfirmCtrl,
                  obscureText: _regConfirmObscure,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    final base = _passwordValidator(v);
                    if (base != null) return base;
                    if (v != _regPassCtrl.text) return 'Senhas não conferem';
                    return null;
                  },
                  decoration: _decoration(
                    context,
                    'Confirmar senha',
                    suffix: IconButton(
                      icon: Icon(_regConfirmObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _regConfirmObscure = !_regConfirmObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: widget.loading
                        ? null
                        : () async {
                            if (_regFormKey.currentState?.validate() ?? false) {
                              await authVm.signUp(
                                _regEmailCtrl.text.trim(),
                                _regPassCtrl.text,
                              );
                            }
                          },
                    child: widget.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Registrar',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.loading
              ? null
              : () => setState(() => _isRegister = !_isRegister),
          child: Text(
            _isRegister ? 'Já tenho conta' : 'Criar uma conta',
            style: textTheme.bodyMedium?.copyWith(color: scheme.primary),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BlurBubble extends StatelessWidget {
  const _BlurBubble({
    required this.color,
    required this.size,
    required this.alignment,
  });
  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _hovering ? 1.02 : 1.0,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}