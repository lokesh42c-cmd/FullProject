import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  List<Appointment> appointments = [];
  bool isLoading = false;

  Future<void> loadAppointments({
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? search,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};

      // Convert DateTime to YYYY-MM-DD for API consumption
      if (fromDate != null) {
        params['from_date'] =
            "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
      }
      if (toDate != null) {
        params['to_date'] =
            "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";
      }
      if (status != null && status != 'ALL') {
        params['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      // Fetch from service with parameters
      appointments = await _service.fetchAppointments(queryParams: params);
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppointment(Map<String, dynamic> data) async {
    await _service.createAppointment(data);
    await loadAppointments();
  }

  Future<void> updateAppointment(int id, Map<String, dynamic> data) async {
    await _service.updateAppointment(id, data);
    await loadAppointments();
  }
}
