import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../providers/appointment_provider.dart';

class AddEditAppointmentDialog extends StatefulWidget {
  final AppointmentProvider provider;
  final Appointment? initialAppointment;

  const AddEditAppointmentDialog({
    super.key,
    required this.provider,
    this.initialAppointment,
  });

  @override
  State<AddEditAppointmentDialog> createState() =>
      _AddEditAppointmentDialogState();
}

class _AddEditAppointmentDialogState extends State<AddEditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController serviceCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController durationCtrl;

  late DateTime date;
  late TimeOfDay time;
  late String status;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final a = widget.initialAppointment;

    nameCtrl = TextEditingController(text: a?.name ?? '');
    phoneCtrl = TextEditingController(text: a?.phone ?? '');
    serviceCtrl = TextEditingController(text: a?.service ?? '');
    notesCtrl = TextEditingController(text: a?.notes ?? '');
    durationCtrl = TextEditingController(
      text: (a?.durationMinutes ?? 30).toString(),
    );

    date = a != null ? DateTime.parse(a.date) : DateTime.now();

    time = a != null ? _parseTime(a.startTime) : TimeOfDay.now();

    status = a?.status ?? 'SCHEDULED';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    serviceCtrl.dispose();
    notesCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const SizedBox(height: 16),
                _field(nameCtrl, 'Name'),
                _field(phoneCtrl, 'Phone'),
                _field(serviceCtrl, 'Service'),
                _notesField(),
                const SizedBox(height: 12),
                _dateTimeRow(),
                _field(
                  durationCtrl,
                  'Duration (minutes)',
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _statusDropdown(),
                const SizedBox(height: 20),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Text(
          widget.initialAppointment == null
              ? 'Add Appointment'
              : 'Edit Appointment',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _notesField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: notesCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Notes',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _pickDate,
            child: Text(DateFormat('yyyy-MM-dd').format(date)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _pickTime,
            child: Text(time.format(context)),
          ),
        ),
      ],
    );
  }

  Widget _statusDropdown() {
    const statuses = [
      'SCHEDULED',
      'RESCHEDULED',
      'COMPLETED',
      'NO_SHOW',
      'CANCELLED',
    ];

    return DropdownButtonFormField<String>(
      value: status,
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => status = v!),
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final payload = {
      'name': nameCtrl.text,
      'phone': phoneCtrl.text,
      'service': serviceCtrl.text,
      'notes': notesCtrl.text,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'start_time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'duration_minutes': int.parse(durationCtrl.text),
      'status': status,
    };

    try {
      if (widget.initialAppointment == null) {
        await widget.provider.addAppointment(payload);
      } else {
        await widget.provider.updateAppointment(
          widget.initialAppointment!.id,
          payload,
        );
      }

      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: time);
    if (t != null) setState(() => time = t);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
