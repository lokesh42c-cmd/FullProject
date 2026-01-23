import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  bool isLoading = false;
  List<Appointment> appointments = [];

  Future<void> loadAppointments({
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    isLoading = true;
    notifyListeners();

    final params = <String, dynamic>{};

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null && status != 'ALL') {
      params['status'] = status;
    }
    if (fromDate != null) {
      params['date_from'] = fromDate.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      params['date_to'] = toDate.toIso8601String().split('T')[0];
    }

    appointments = await _service.fetchAppointments(params: params);

    isLoading = false;
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appointment) async {
    final created = await _service.createAppointment(appointment);
    appointments.insert(0, created);
    notifyListeners();
  }

  Future<void> updateAppointment(int id, Appointment appointment) async {
    final updated = await _service.updateAppointment(id, appointment);
    final index = appointments.indexWhere((e) => e.id == id);
    if (index != -1) {
      appointments[index] = updated;
    }
    notifyListeners();
  }
}
