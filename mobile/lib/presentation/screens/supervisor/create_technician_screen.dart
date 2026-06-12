import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';

class CreateTechnicianScreen extends ConsumerStatefulWidget {
  const CreateTechnicianScreen({super.key});

  @override
  ConsumerState<CreateTechnicianScreen> createState() =>
      _CreateTechnicianScreenState();
}

class _CreateTechnicianScreenState extends ConsumerState<CreateTechnicianScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(technicianListNotifierProvider.notifier)
          .createTechnician(_usernameCtrl.text.trim(), _nameCtrl.text.trim());
      if (context.mounted) context.pop();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().contains('409')
            ? 'El nombre de usuario ya está en uso'
            : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo técnico')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre completo', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre de usuario', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
              enabled: !_loading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 8),
            const Text(
              'La contraseña inicial será COLBO2026.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear técnico'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
