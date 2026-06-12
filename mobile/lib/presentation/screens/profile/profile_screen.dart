import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di.dart';
import '../../../domain/models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  void _startEdit(User user) {
    _nameCtrl.text = user.displayName;
    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    setState(() => _isEditing = true);
  }

  void _cancelEdit(User user) {
    _nameCtrl.text = user.displayName;
    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    setState(() => _isEditing = false);
  }

  Future<void> _save(User user) async {
    final notifier = ref.read(profileNotifierProvider.notifier);
    try {
      if (_nameCtrl.text.trim().isNotEmpty &&
          _nameCtrl.text.trim() != user.displayName) {
        await notifier.updateDisplayName(_nameCtrl.text.trim());
      }
      if (_currentPwCtrl.text.isNotEmpty && _newPwCtrl.text.isNotEmpty) {
        if (_newPwCtrl.text.length < 6) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres'),
          ));
          return;
        }
        await notifier.changePassword(_currentPwCtrl.text, _newPwCtrl.text);
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar perfil' : 'Mi perfil'),
        actions: [
          if (!_isEditing)
            profileState.whenOrNull(
              data: (user) => IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => _startEdit(user),
              ),
            ) ??
                const SizedBox.shrink(),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) => _isEditing
            ? _buildEditForm(context, user, cs)
            : _buildProfileView(context, user, cs),
      ),
    );
  }

  // ── View mode ────────────────────────────────────────────────────────────────

  Widget _buildProfileView(BuildContext context, User user, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name row
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.person_outline,
                          color: cs.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.role == Role.supervisor
                                ? 'Supervisor'
                                : 'Técnico',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Código personal
                const _FieldLabel('Código personal'),
                const SizedBox(height: 6),
                _ReadOnlyField(value: user.username),
                const SizedBox(height: 16),

                // Rol
                const _FieldLabel('Rol'),
                const SizedBox(height: 6),
                _RolBadge(
                  label: user.role == Role.supervisor ? 'Supervisor' : 'Técnico',
                  color: cs.primary,
                ),
                const SizedBox(height: 16),

                // Estado
                const _FieldLabel('Estado'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Activo',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _startEdit(user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit mode ────────────────────────────────────────────────────────────────

  Widget _buildEditForm(BuildContext context, User user, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.person_outline, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuración de Perfil',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            user.role == Role.supervisor
                                ? 'Privilegios de supervisor'
                                : 'Perfil de técnico',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nombre completo
                const _FieldLabel('Nombre completo'),
                const SizedBox(height: 6),
                _EditField(controller: _nameCtrl),
                const SizedBox(height: 16),

                // Código personal (read-only)
                const _FieldLabel('Código personal'),
                const SizedBox(height: 6),
                _ReadOnlyField(value: user.username),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Text(
                    'El código no puede modificarse',
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 16),

                // Rol (display-only)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Rol'),
                          const SizedBox(height: 6),
                          _RolBadge(
                            label: user.role == Role.supervisor
                                ? 'Supervisor'
                                : 'Técnico',
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 16),

                // Cambiar contraseña
                const _FieldLabel('Contraseña actual'),
                const SizedBox(height: 6),
                _EditField(
                  controller: _currentPwCtrl,
                  obscureText: true,
                  hintText: '••••••••',
                ),
                const SizedBox(height: 12),
                const _FieldLabel('Nueva contraseña'),
                const SizedBox(height: 6),
                _EditField(
                  controller: _newPwCtrl,
                  obscureText: true,
                  hintText: 'Mínimo 6 caracteres',
                ),
                const SizedBox(height: 24),

                // Guardar cambios
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => _save(user),
                    child: const Text('Guardar cambios'),
                  ),
                ),
                const SizedBox(height: 10),

                // Cancelar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => _cancelEdit(user),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared private widgets ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
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
      style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
          color: Color(0xFF1D1D1F)),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    this.obscureText = false,
    this.hintText,
  });
  final TextEditingController controller;
  final bool obscureText;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
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
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _RolBadge extends StatelessWidget {
  const _RolBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
