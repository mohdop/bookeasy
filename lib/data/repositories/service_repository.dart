import '../providers/supabase_provider.dart';
import '../models/service.dart';

class ServiceRepository {
  final _supabase = SupabaseProvider.client;
  
  // Get services by business ID
  Future<List<Service>> getServicesByBusinessId(String businessId) async {
    final data = await _supabase
        .from('services')
        .select()
        .eq('business_id', businessId)
        .order('order_index');
    
    return data.map((json) => Service.fromJson(json)).toList();
  }
  
  // Get service by ID
  Future<Service> getServiceById(String id) async {
    final data = await _supabase
        .from('services')
        .select()
        .eq('id', id)
        .single();
    
    return Service.fromJson(data);
  }
  
  // Create service
  Future<Service> createService(Map<String, dynamic> serviceData) async {
    final data = await _supabase
        .from('services')
        .insert(serviceData)
        .select()
        .single();
    
    return Service.fromJson(data);
  }
  
  // Update service
  Future<Service> updateService(String id, Map<String, dynamic> updates) async {
    final data = await _supabase
        .from('services')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    
    return Service.fromJson(data);
  }
  
  // Delete service
  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
  }
  
  // Toggle service active status
  Future<void> toggleServiceStatus(String id, bool isActive) async {
    await _supabase
        .from('services')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
