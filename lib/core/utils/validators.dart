class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }
    
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Téléphone requis';
    }
    
    // Remove spaces and special characters
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.length < 10) {
      return 'Numéro invalide';
    }
    
    return null;
  }
  
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? "Ce champ"} est requis';
    }
    return null;
  }
  
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Prix requis';
    }
    
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Prix invalide';
    }
    
    return null;
  }
  
  static String? duration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Durée requise';
    }
    
    final duration = int.tryParse(value);
    if (duration == null || duration <= 0) {
      return 'Durée invalide';
    }
    
    return null;
  }
}