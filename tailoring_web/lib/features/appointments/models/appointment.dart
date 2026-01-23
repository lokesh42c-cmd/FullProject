class Appointment {
  final int id;
  final String name;
  final String phone;
  final String date;
  final String startTime;
  final int durationMinutes;
  final String? service;
  final String? notes;
  final String status;

  Appointment({
    required this.id,
    required this.name,
    required this.phone,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    this.service,
    this.notes,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      date: json['date'],
      startTime: json['start_time'],
      durationMinutes: json['duration_minutes'],
      service: json['service'],
      notes: json['notes'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'date': date,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'service': service,
      'notes': notes,
      'status': status,
    };
  }
}
