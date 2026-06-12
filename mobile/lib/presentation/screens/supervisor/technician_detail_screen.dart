import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../domain/models/user.dart';

class TechnicianDetailScreen extends ConsumerStatefulWidget {
  const TechnicianDetailScreen({super.key, required this.technicianId});
  final String technicianId;

  @override
  ConsumerState<TechnicianDetailScreen> createState() =>
      _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState
    extends ConsumerState<TechnicianDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  int _selectedShift = 2;
  bool _initialized = false;

  static const _shiftLabels = {1: 'Noche', 2: 'Mañana', 3: 'Tarde'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _initFields(User tech) {
    if (_initialized) return;
    _nameCtrl.text = tech.displayName;
    _initialized = true;
  }

  Future<void> _save() async {
    try {
      await ref
          .read(technicianListNotifierProvider.notifier)
          .editTechnician(widget.technicianId,
              displayName: _nameCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(User tech) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          '¿Está seguro de que desea eliminar la cuenta de ${tech.displayName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(technicianListNotifierProvider.notifier)
          .deleteTechnician(widget.technicianId);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('409')
          ? 'No se puede eliminar: el técnico tiene órdenes de trabajo asignadas'
          : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianListNotifierProvider);
    final tech = state.valueOrNull?.firstWhere(
      (t) => t.id == widget.technicianId,
      orElse: () => throw StateError('not found'),
    );

    if (tech == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _initFields(tech);
    final cs = Theme.of(context).colorScheme;
    final isActive = tech.status == UserStatus.active;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Editar usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Main edit card ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                              tech.role == Role.supervisor
                                  ? 'Modificando privilegios de supervisor'
                                  : 'Modificando datos del técnico',
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
                  _ReadOnlyField(value: tech.username),
                  const SizedBox(height: 4),
                  Text(
                    'El código no puede modificarse',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),

                  // Rol + Turno
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Rol'),
                            const SizedBox(height: 6),
                            _RolBadge(
                              label: tech.role == Role.supervisor
                                  ? 'Supervisor'
                                  : 'Técnico',
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Turno'),
                            const SizedBox(height: 6),
                            _TurnoDropdown(
                              value: _selectedShift,
                              labels: _shiftLabels,
                              onChanged: (v) =>
                                  setState(() => _selectedShift = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  const _FieldLabel('Contraseña'),
                  const SizedBox(height: 6),
                  _EditField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    hintText: '••••••••',
                  ),
                  const SizedBox(height: 24),

                  // Guardar cambios
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cancelar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => context.pop(),
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
            const SizedBox(height: 16),

            // ── Info row ────────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: _InfoTile(
                    label: 'ÚLTIMO ACCESO',
                    child: Text('--',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    label: 'ESTADO',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Activo' : 'Desactivado',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Eliminar cuenta ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _delete(tech),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar cuenta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          Icon(Icons.keyboard_arrow_down, color: color, size: 20),
        ],
      ),
    );
  }
}

class _TurnoDropdown extends StatelessWidget {
  const _TurnoDropdown({
    required this.value,
    required this.labels,
    required this.onChanged,
  });
  final int value;
  final Map<int, String> labels;
  final ValueChanged<int?> onChanged;

  static const _teal = Color(0xFF31D0AA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: _teal,
        items: labels.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: Colors.white, size: 20),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
