import 'package:flutter/material.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialAppointment?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialAppointment?.phone ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialAppointment == null
            ? 'New Appointment'
            : 'Edit Appointment',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final data = {
              'name': _nameController.text,
              'phone': _phoneController.text,
            };
            if (widget.initialAppointment == null) {
              await widget.provider.addAppointment(data);
            } else {
              await widget.provider.updateAppointment(
                widget.initialAppointment!.id,
                data,
              );
            }
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
