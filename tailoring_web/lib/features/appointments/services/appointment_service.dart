import 'package:tailoring_web/core/api/api_client.dart';
import '../models/appointment.dart';

class AppointmentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Appointment>> fetchAppointments({
    Map<String, dynamic>? params,
  }) async {
    final response = await _apiClient.get(
      'appointments/',
      queryParameters: params,
    );

    final responseData = response.data;
    final List data = responseData is Map
        ? responseData['results'] ?? []
        : responseData;

    return data.map((e) => Appointment.fromJson(e)).toList();
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    final response = await _apiClient.post(
      'appointments/',
      data: appointment.toJson(),
    );
    return Appointment.fromJson(response.data);
  }

  Future<Appointment> updateAppointment(int id, Appointment appointment) async {
    final response = await _apiClient.put(
      'appointments/$id/',
      data: appointment.toJson(),
    );
    return Appointment.fromJson(response.data);
  }

  Future<void> deleteAppointment(int id) async {
    await _apiClient.delete('appointments/$id/');
  }
}
