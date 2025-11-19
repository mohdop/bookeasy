import '../providers/supabase_provider.dart';
import '../models/business.dart';

class BusinessRepository {
  final _supabase = SupabaseProvider.client;
  
  // Get business by owner ID
  Future<Business?> getBusinessByOwnerId(String ownerId) async {
    try {
      final data = await _supabase
          .from('businesses')
          .select()
          .eq('owner_id', ownerId)
          .maybeSingle();
      
      if (data == null) return null;
      return Business.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get business by ID
  Future<Business> getBusinessById(String id) async {
    final data = await _supabase
        .from('businesses')
        .select()
        .eq('id', id)
        .single();
    
    return Business.fromJson(data);
  }
  
  // Create business
  Future<Business> createBusiness(Map<String, dynamic> businessData) async {
    final data = await _supabase
        .from('businesses')
        .insert(businessData)
        .select()
        .single();
    
    return Business.fromJson(data);
  }
  
  // Update business
  Future<Business> updateBusiness(String id, Map<String, dynamic> updates) async {
    final data = await _supabase
        .from('businesses')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    
    return Business.fromJson(data);
  }
  
  // Delete business
  Future<void> deleteBusiness(String id) async {
    await _supabase.from('businesses').delete().eq('id', id);
  }
}