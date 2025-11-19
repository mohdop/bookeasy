import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/appointment.dart';
import '../../core/utils/date_utils.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        return AppTheme.success;
      case AppointmentStatus.pending:
        return AppTheme.warning;
      case AppointmentStatus.cancelled:
        return AppTheme.error;
      case AppointmentStatus.completed:
        return AppTheme.gray;
      case AppointmentStatus.noShow:
        return AppTheme.error;
    }
  }

  Color _getStatusBgColor() {
    return _getStatusColor().withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusLarge,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      appointment.service?.name ?? 'Service',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appointment.clientName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.gray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppDateUtils.getRelativeDate(appointment.appointmentDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.gray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppDateUtils.formatTime(appointment.startTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}