class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final BusinessCategory category;
  final String? address;
  final String? city;
  final String? postalCode;
  final String phone;
  final String? email;
  final String? logoUrl;
  final Map<String, OpeningHours> openingHours;
  final int slotDuration; // minutes
  final int bufferTime; // minutes
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.category,
    this.address,
    this.city,
    this.postalCode,
    required this.phone,
    this.email,
    this.logoUrl,
    required this.openingHours,
    this.slotDuration = 30,
    this.bufferTime = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final hoursMap = json['opening_hours'] as Map<String, dynamic>;
    final openingHours = <String, OpeningHours>{};
    
    hoursMap.forEach((day, hours) {
      openingHours[day] = OpeningHours.fromJson(hours);
    });

    return Business(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      category: BusinessCategory.fromString(json['category']),
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      phone: json['phone'],
      email: json['email'],
      logoUrl: json['logo_url'],
      openingHours: openingHours,
      slotDuration: json['slot_duration'] ?? 30,
      bufferTime: json['buffer_time'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final hoursMap = <String, dynamic>{};
    openingHours.forEach((day, hours) {
      hoursMap[day] = hours.toJson();
    });

    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'category': category.value,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'opening_hours': hoursMap,
      'slot_duration': slotDuration,
      'buffer_time': bufferTime,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool isOpenOn(DateTime date) {
    final dayName = _getDayName(date.weekday);
    final hours = openingHours[dayName];
    return hours != null && !hours.closed;
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}

class OpeningHours {
  final String open;
  final String close;
  final bool closed;

  OpeningHours({
    required this.open,
    required this.close,
    this.closed = false,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      open: json['open'],
      close: json['close'],
      closed: json['closed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'closed': closed,
    };
  }
}

enum BusinessCategory {
  barber,
  coach,
  nailArtist,
  tutor,
  other;

  String get value {
    switch (this) {
      case BusinessCategory.barber:
        return 'barber';
      case BusinessCategory.coach:
        return 'coach';
      case BusinessCategory.nailArtist:
        return 'nail_artist';
      case BusinessCategory.tutor:
        return 'tutor';
      case BusinessCategory.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case BusinessCategory.barber:
        return 'Coiffeur / Barbier';
      case BusinessCategory.coach:
        return 'Coach';
      case BusinessCategory.nailArtist:
        return 'Esthéticienne';
      case BusinessCategory.tutor:
        return 'Tuteur';
      case BusinessCategory.other:
        return 'Autre';
    }
  }

  static BusinessCategory fromString(String value) {
    switch (value) {
      case 'barber':
        return BusinessCategory.barber;
      case 'coach':
        return BusinessCategory.coach;
      case 'nail_artist':
        return BusinessCategory.nailArtist;
      case 'tutor':
        return BusinessCategory.tutor;
      default:
        return BusinessCategory.other;
    }
  }
}