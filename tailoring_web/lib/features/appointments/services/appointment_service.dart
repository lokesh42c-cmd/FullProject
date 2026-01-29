import 'package:tailoring_web/core/api/api_client.dart';
import '../models/appointment.dart';

class AppointmentService {
  final ApiClient _apiClient;

  AppointmentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// GET list
  Future<List<Appointment>> fetchAppointments({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _apiClient.get(
      'appointments/',
      queryParameters: queryParams,
    );

    final data = response.data;

    final List list = data is Map && data.containsKey('results')
        ? data['results']
        : data;

    return list
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// CREATE
  Future<void> createAppointment(Map<String, dynamic> data) async {
    await _apiClient.post('appointments/', data: data);
  }

  /// UPDATE
  Future<void> updateAppointment(int id, Map<String, dynamic> data) async {
    await _apiClient.put('appointments/$id/', data: data);
  }

  /// DELETE (optional, safe)
  Future<void> deleteAppointment(int id) async {
    await _apiClient.delete('appointments/$id/');
  }
}
