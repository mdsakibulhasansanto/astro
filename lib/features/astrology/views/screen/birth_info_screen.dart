import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/riverpod/auth_provider.dart';
import '../../model/birth_profile_model.dart';
import '../../riverpod/astrology_provider.dart';

const _customPlace = '__custom__';

/// Birth Information form. Saving it runs the chart calculation.
class BirthInfoScreen extends ConsumerStatefulWidget {
  const BirthInfoScreen({super.key});

  @override
  ConsumerState<BirthInfoScreen> createState() => _BirthInfoScreenState();
}

class _BirthInfoScreenState extends ConsumerState<BirthInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _placeName = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _tz = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  bool _timeUnknown = false;
  String _place = cities.first.name;
  KuaBasis _kuaBasis = KuaBasis.female;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(astrologyStateNotifierProvider).profile;
    final user = ref.read(authStateNotifierProvider).user;
    if (existing != null) {
      _name.text = existing.name;
      _date = existing.birthDate;
      if (existing.hasBirthTime) {
        final parts = existing.birthTime!.split(':');
        _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _timeUnknown = true;
      }
      final known = cities.where((c) => c.name == existing.birthPlace);
      if (known.isNotEmpty) {
        _place = known.first.name;
      } else {
        _place = _customPlace;
        _placeName.text = existing.birthPlace;
        _lat.text = existing.latitude.toString();
        _lon.text = existing.longitude.toString();
        _tz.text = existing.timezone;
      }
      _kuaBasis = existing.kuaBasis;
    } else {
      _name.text = user?.name ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _placeName, _lat, _lon, _tz]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 25, 6, 15),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    if (_date == null) setState(() => _dateError = 'Birth date is required');
    if (!formOk || _date == null) return;
    if (!_timeUnknown && _time == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a birth time, or tick "I don\'t know".')));
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final existing = ref.read(astrologyStateNotifierProvider).profile;
    final city = _place == _customPlace ? null : cities.firstWhere((c) => c.name == _place);

    final profile = BirthProfileModel(
      id: existing?.id,
      userId: userId,
      name: _name.text,
      birthDate: _date!,
      birthTime: _timeUnknown
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      birthPlace: city?.name ?? _placeName.text.trim(),
      latitude: city?.latitude ?? double.parse(_lat.text.trim()),
      longitude: city?.longitude ?? double.parse(_lon.text.trim()),
      timezone: city?.timezone ?? _tz.text.trim(),
      kuaBasis: _kuaBasis,
    );

    final ok = await ref.read(astrologyStateNotifierProvider.notifier).saveAndCalculate(profile);
    if (!mounted) return;
    if (ok) {
      context.goNamed(RouteNames.astrology);
    } else {
      final msg = ref.read(astrologyStateNotifierProvider).message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg ?? 'Could not calculate your chart.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(astrologyStateNotifierProvider.select((s) => s.isSaving));
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Birth information')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const NoteText(
              'Your chart is calculated by an astronomy engine from these details. '
              'An exact birth time gives you a rising sign and houses.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.requiredText(v, 'Name'),
            ),
            const SizedBox(height: 12),
            _PickerField(
              label: 'Birth date',
              value: _date == null ? null : formatReadableDate(_date!),
              icon: Icons.calendar_today_outlined,
              errorText: _dateError,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            _PickerField(
              label: 'Birth time',
              value: _timeUnknown ? 'Unknown' : _time?.format(context),
              icon: Icons.schedule_outlined,
              onTap: _timeUnknown ? null : _pickTime,
            ),
            CheckboxListTile(
              value: _timeUnknown,
              onChanged: (v) => setState(() => _timeUnknown = v ?? false),
              title: const Text("I don't know my birth time"),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: c.brass,
            ),
            DropdownButtonFormField<String>(
              initialValue: _place,
              decoration: const InputDecoration(labelText: 'Birthplace'),
              isExpanded: true,
              items: [
                for (final city in cities)
                  DropdownMenuItem(value: city.name, child: Text(city.name)),
                const DropdownMenuItem(
                  value: _customPlace,
                  child: Text('Another place (enter coordinates)'),
                ),
              ],
              onChanged: (v) => setState(() => _place = v ?? cities.first.name),
            ),
            if (_place == _customPlace) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeName,
                decoration: const InputDecoration(labelText: 'Place name'),
                validator: (v) => Validators.requiredText(v, 'Place name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      validator: Validators.numberInRange(-66, 66, 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lon,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      validator: Validators.numberInRange(-180, 180, 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tz,
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  hintText: 'e.g. Asia/Dhaka',
                  helperText: 'IANA timezone name of the birthplace',
                ),
                validator: (v) => Validators.requiredText(v, 'Timezone'),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<KuaBasis>(
              initialValue: _kuaBasis,
              decoration: const InputDecoration(
                labelText: 'Kua number basis',
                helperText:
                    'Feng shui works out your best directions from birth year and birth sex.',
                helperMaxLines: 2,
              ),
              items: [
                for (final k in KuaBasis.values) DropdownMenuItem(value: k, child: Text(k.label)),
              ],
              onChanged: (v) => setState(() => _kuaBasis = v ?? KuaBasis.female),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _submit,
              child: Text(saving ? 'Calculating…' : 'Calculate my chart'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
          errorText: errorText,
          enabled: onTap != null,
        ),
        isEmpty: value == null,
        child: value == null ? null : Text(value!),
      ),
    );
  }
}
