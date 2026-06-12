import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) return;
    await ref.read(authNotifierProvider.notifier).login(username, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncError) {
        final err = next.error;
        String msg;
        if (err is DioException && err.response?.statusCode == 401) {
          msg = 'Usuario o contraseña incorrectos';
        } else if (err is DioException &&
            (err.type == DioExceptionType.connectionTimeout ||
                err.type == DioExceptionType.connectionError)) {
          msg = 'No se pudo conectar al servidor';
        } else {
          msg = 'Error inesperado. Intente de nuevo.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: cs.error),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0E7FF), Colors.white],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                // Hero image card
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/portada.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF0E7FF), Color(0xFFE0D0FF)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.engineering,
                            size: 110,
                            color: Color(0x596338E8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          'Bienvenido de nuevo',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Gestiona tus tareas de mantenimiento con\neficiencia y precisión.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Username field
                      const _FieldLabel('Correo electrónico'),
                      const SizedBox(height: 8),
                      _StyledField(
                        controller: _usernameCtrl,
                        hintText: 'ejemplo@profesional.com',
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.next,
                        enabled: !authState.isLoading,
                      ),
                      const SizedBox(height: 20),

                      // Password label row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _FieldLabel('Contraseña'),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _StyledField(
                        controller: _passwordCtrl,
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !authState.isLoading,
                        onSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: authState.isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Page indicator dots
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dot(active: true, color: cs.primary),
                            const SizedBox(width: 6),
                            _Dot(active: false, color: cs.primary),
                            const SizedBox(width: 6),
                            _Dot(active: false, color: cs.primary),
                          ],
                        ),
                      ),
                    ],
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1F),
          ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      obscureText: obscureText,
      textInputAction: textInputAction,
      enabled: enabled,
      onSubmitted: onSubmitted,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.color});
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
