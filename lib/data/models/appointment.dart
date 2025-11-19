import 'package:bookeasy/data/models/business.dart';
import 'package:bookeasy/data/models/service.dart';

class Appointment {
  final String id;
  final String businessId;
  final String serviceId;
  final String? clientId;
  final String clientName;
  final String clientPhone;
  final String? clientEmail;
  final DateTime appointmentDate;
  final String startTime;
  final String endTime;
  final AppointmentStatus status;
  final String? notes;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (optional, loaded separately)
  final Service? service;
  final Business? business;

  Appointment({
    required this.id,
    required this.businessId,
    required this.serviceId,
    this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.clientEmail,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.pending,
    this.notes,
    this.cancellationReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.service,
    this.business,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      businessId: json['business_id'],
      serviceId: json['service_id'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      clientEmail: json['client_email'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: AppointmentStatus.fromString(json['status']),
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      service: json['service'] != null ? Service.fromJson(json['service']) : null,
      business: json['business'] != null ? Business.fromJson(json['business']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'service_id': serviceId,
      'client_id': clientId,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_email': clientEmail,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'status': status.value,
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DateTime get fullStartDateTime {
    final time = startTime.split(':');
    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(time[0]),
      int.parse(time[1]),
    );
  }

  bool get isPast => fullStartDateTime.isBefore(DateTime.now());
  bool get isToday => isSameDay(appointmentDate, DateTime.now());
  bool get isTomorrow => isSameDay(appointmentDate, DateTime.now().add(Duration(days: 1)));

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow;

  String get value {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.noShow:
        return 'Absent';
    }
  }

  static AppointmentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }
}
