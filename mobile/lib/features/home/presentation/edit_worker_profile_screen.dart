import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/user_profile_provider.dart';

/// Offline-first profile editor for the authenticated ASHA worker.
class EditWorkerProfileScreen extends ConsumerStatefulWidget {
  const EditWorkerProfileScreen({super.key});

  @override
  ConsumerState<EditWorkerProfileScreen> createState() =>
      _EditWorkerProfileScreenState();
}

class _EditWorkerProfileScreenState
    extends ConsumerState<EditWorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _village;
  late final TextEditingController _subcentre;
  late final TextEditingController _phc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _name = TextEditingController(text: profile?.name ?? '');
    _phone = TextEditingController(text: profile?.phone ?? '');
    _village = TextEditingController(text: profile?.village ?? '');
    _subcentre = TextEditingController(text: profile?.subcentre ?? '');
    _phc = TextEditingController(text: profile?.phc ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _village.dispose();
    _subcentre.dispose();
    _phc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(userProfileProvider.notifier).updateEditableProfile(
          name: _name.text,
          phone: _phone.text,
          village: _village.text,
          subcentre: _subcentre.text,
          phc: _phc.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved locally.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: AshaColors.primary,
                  child: Text(
                    profile?.initials ?? 'AS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Update the details used for your offline profile and field records.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AshaColors.textSecondary),
              ),
              const SizedBox(height: 22),
              _field(_name, 'Full name', Icons.person_outline, required: true),
              _field(_phone, 'Mobile number', Icons.phone_outlined),
              _field(_village, 'Village / area', Icons.location_on_outlined),
              _field(_subcentre, 'Sub-centre', Icons.local_hospital_outlined),
              _field(_phc, 'PHC', Icons.medical_services_outlined),
              const SizedBox(height: 8),
              _readOnly('ASHA ID', profile?.ashaId ?? '', Icons.badge_outlined),
              _readOnly('Role', profile?.role ?? 'ASHA', Icons.verified_user_outlined),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'Enter your name'
                : null
            : null,
      ),
    );
  }

  Widget _readOnly(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(value.isEmpty ? 'Not available' : value),
      ),
    );
  }
}
