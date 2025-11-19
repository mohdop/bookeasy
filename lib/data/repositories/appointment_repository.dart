import '../providers/supabase_provider.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  final _supabase = SupabaseProvider.client;
  
  // Get appointments by business ID
  Future<List<Appointment>> getAppointmentsByBusinessId(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('appointments')
        .select('*, service:services(*)')
        .eq('business_id', businessId);
    
    if (startDate != null) {
      query = query.gte('appointment_date', startDate.toIso8601String().split('T')[0]);
    }
    
    if (endDate != null) {
      query = query.lte('appointment_date', endDate.toIso8601String().split('T')[0]);
    }
    
    final data = await query.order('appointment_date').order('start_time');
    
    return data.map((json) => Appointment.fromJson(json)).toList();
  }
  
  // Get appointments by client ID
  Future<List<Appointment>> getAppointmentsByClientId(String clientId) async {
    final data = await _supabase
        .from('appointments')
        .select('*, service:services(*), business:businesses(*)')
        .eq('client_id', clientId)
        .order('appointment_date', ascending: false);
    
    return data.map((json) => Appointment.fromJson(json)).toList();
  }
  
  // Get appointment by ID
  Future<Appointment> getAppointmentById(String id) async {
    final data = await _supabase
        .from('appointments')
        .select('*, service:services(*)')
        .eq('id', id)
        .single();
    
    return Appointment.fromJson(data);
  }
  
  // Create appointment
  Future<Appointment> createAppointment(Map<String, dynamic> appointmentData) async {
    final data = await _supabase
        .from('appointments')
        .insert(appointmentData)
        .select('*, service:services(*)')
        .single();
    
    return Appointment.fromJson(data);
  }
  
  // Update appointment status
  Future<void> updateAppointmentStatus(String id, String status) async {
    await _supabase
        .from('appointments')
        .update({'status': status})
        .eq('id', id);
  }
  
  // Cancel appointment
  Future<void> cancelAppointment(String id, String reason) async {
    await _supabase
        .from('appointments')
        .update({
          'status': 'cancelled',
          'cancellation_reason': reason,
          'cancelled_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
  
  // Get available slots
  Future<List<String>> getAvailableSlots({
    required String businessId,
    required DateTime date,
    required String serviceId,
  }) async {
    final response = await _supabase.rpc(
      'get_available_slots',
      params: {
        'p_business_id': businessId,
        'p_date': date.toIso8601String().split('T')[0],
        'p_service_id': serviceId,
      },
    );
    
    return (response as List)
        .map((slot) => slot['slot_time'] as String)
        .toList();
  }
}
