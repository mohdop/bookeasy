class Subscription {
  final String id;
  final String businessId;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final SubscriptionPlan planType;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? trialEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.businessId,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.planType = SubscriptionPlan.free,
    this.status = SubscriptionStatus.inactive,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.trialEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      businessId: json['business_id'],
      stripeCustomerId: json['stripe_customer_id'],
      stripeSubscriptionId: json['stripe_subscription_id'],
      planType: SubscriptionPlan.fromString(json['plan_type']),
      status: SubscriptionStatus.fromString(json['status']),
      currentPeriodStart: json['current_period_start'] != null 
          ? DateTime.parse(json['current_period_start']) 
          : null,
      currentPeriodEnd: json['current_period_end'] != null 
          ? DateTime.parse(json['current_period_end']) 
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
      trialEnd: json['trial_end'] != null ? DateTime.parse(json['trial_end']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'plan_type': planType.value,
      'status': status.value,
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'cancel_at_period_end': cancelAtPeriodEnd,
      'trial_end': trialEnd?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPremium => planType == SubscriptionPlan.premium && isActive;
  bool get isInTrial => trialEnd != null && DateTime.now().isBefore(trialEnd!);
}

enum SubscriptionPlan {
  free,
  premium;

  String get value {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.premium:
        return 'premium';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Gratuit';
      case SubscriptionPlan.premium:
        return 'Premium';
    }
  }

  static SubscriptionPlan fromString(String value) {
    return value == 'premium' ? SubscriptionPlan.premium : SubscriptionPlan.free;
  }
}

enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  pastDue;

  String get value {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.inactive:
        return 'inactive';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.pastDue:
        return 'past_due';
    }
  }

  static SubscriptionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return SubscriptionStatus.active;
      case 'inactive':
        return SubscriptionStatus.inactive;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      default:
        return SubscriptionStatus.inactive;
    }
  }
}