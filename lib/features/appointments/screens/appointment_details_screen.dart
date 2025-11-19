// ignore_for_file: unused_element

import 'package:bookeasy/app/theme.dart';
import 'package:bookeasy/core/utils/date_utils.dart' as app_date_utils show AppDateUtils;
import 'package:bookeasy/data/models/appointment.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/custom_button.dart';


class _AppointmentDetailsSheet extends StatelessWidget {
  final Appointment appointment;
  final Function(Appointment, AppointmentStatus) onStatusChange;

  const _AppointmentDetailsSheet({
    required this.appointment,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                      Text(
                        appointment.service?.name ?? 'Service',
                        style: context.textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      
                      // Status Badge
                      _StatusBadge(status: appointment.status),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Client Info
                      _InfoSection(
                        icon: Icons.person,
                        title: 'Client',
                        items: [
                          _InfoItem(
                            label: 'Nom',
                            value: appointment.clientName,
                          ),
                          _InfoItem(
                            label: 'Téléphone',
                            value: appointment.clientPhone,
                          ),
                          if (appointment.clientEmail != null)
                            _InfoItem(
                              label: 'Email',
                              value: appointment.clientEmail!,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date & Time
                      _InfoSection(
                        icon: Icons.calendar_today,
                        title: 'Date et heure',
                        items: [
                          _InfoItem(
                            label: 'Date',
                            value: app_date_utils.AppDateUtils.formatDate(
                              appointment.appointmentDate,
                            ),
                          ),
                          _InfoItem(
                            label: 'Heure',
                            value: '${app_date_utils.AppDateUtils.formatTime(appointment.startTime)} - ${app_date_utils.AppDateUtils.formatTime(appointment.endTime)}',
                          ),
                          _InfoItem(
                            label: 'Durée',
                            value: appointment.service?.formattedDuration ?? '',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Service Info
                      _InfoSection(
                        icon: Icons.content_cut,
                        title: 'Service',
                        items: [
                          _InfoItem(
                            label: 'Prix',
                            value: appointment.service?.formattedPrice ?? '',
                          ),
                        ],
                      ),
                      
                      if (appointment.notes != null) ...[
                        const SizedBox(height: 24),
                        _InfoSection(
                          icon: Icons.note,
                          title: 'Notes',
                          items: [
                            _InfoItem(
                              label: '',
                              value: appointment.notes!,
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Actions
                      if (appointment.status == AppointmentStatus.pending) ...[
                        CustomButton(
                          text: 'Confirmer',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.confirmed,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Annuler',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.cancelled,
                            );
                            Navigator.pop(context);
                          },
                          isOutlined: true,
                          color: AppTheme.error,
                          icon: Icons.cancel,
                        ),
                      ],
                      
                      if (appointment.status == AppointmentStatus.confirmed) ...[
                        CustomButton(
                          text: 'Marquer comme terminé',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.completed,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icons.check,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Client absent',
                          onPressed: () {
                            onStatusChange(
                              appointment,
                              AppointmentStatus.noShow,
                            );
                            Navigator.pop(context);
                          },
                          isOutlined: true,
                          color: AppTheme.warning,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper Widgets
class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  Color _getColor() {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppTheme.success;
      case AppointmentStatus.pending:
        return AppTheme.warning;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        return AppTheme.error;
      case AppointmentStatus.completed:
        return AppTheme.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: context.textTheme.labelMedium?.copyWith(
          color: _getColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppTheme.gray,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
