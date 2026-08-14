/// Premium plan model
class PremiumPlan {
  final String id;
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final String description;

  PremiumPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.description,
  });

  static PremiumPlan get basic => PremiumPlan(
        id: 'basic',
        name: 'Básico',
        monthlyPrice: 0,
        yearlyPrice: 0,
        features: [
          'Crear perfil',
          '1 anuncio activo',
          'Buscar pisos',
          '15 likes al día',
          'Match y chat',
          'Filtros básicos',
          'Verificación opcional',
        ],
        description: 'Perfecto para empezar a buscar compañeros',
      );

  static PremiumPlan get premium => PremiumPlan(
        id: 'premium',
        name: 'Premium',
        monthlyPrice: 9.99,
        yearlyPrice: 79.99,
        features: [
          'Todo lo básico',
          'Likes ilimitados',
          'Hasta 10 anuncios activos',
          'Ver quién te ha dado like',
          'Deshacer swipes',
          '1 Boost semanal',
          'Prioridad en recomendaciones',
          'Filtros avanzados',
          'Badge Premium',
          'Sin anuncios',
          'Estadísticas completas',
          'Soporte prioritario',
        ],
        description: 'Alquila más rápido con funciones exclusivas',
      );
}

/// User limits based on plan
class UserLimits {
  final int dailySwipes;
  final int activeListings;
  final int weeklyBoosts;
  final bool advancedFilters;
  final bool seeWhoLikedYou;
  final bool undoSwipe;
  final bool priorityRecommendations;
  final bool premiumBadge;
  final bool noAds;
  final bool fullStatistics;
  final bool prioritySupport;

  UserLimits({
    required this.dailySwipes,
    required this.activeListings,
    required this.weeklyBoosts,
    required this.advancedFilters,
    required this.seeWhoLikedYou,
    required this.undoSwipe,
    required this.priorityRecommendations,
    required this.premiumBadge,
    required this.noAds,
    required this.fullStatistics,
    required this.prioritySupport,
  });

  factory UserLimits.fromPlan(String planId) {
    switch (planId) {
      case 'premium':
        return UserLimits.premium;
      default:
        return UserLimits.basic;
    }
  }

  static UserLimits get basic => UserLimits(
        dailySwipes: 15,
        activeListings: 1,
        weeklyBoosts: 0,
        advancedFilters: false,
        seeWhoLikedYou: false,
        undoSwipe: false,
        priorityRecommendations: false,
        premiumBadge: false,
        noAds: false,
        fullStatistics: false,
        prioritySupport: false,
      );

  static UserLimits get premium => UserLimits(
        dailySwipes: -1, // Unlimited
        activeListings: 10,
        weeklyBoosts: 1,
        advancedFilters: true,
        seeWhoLikedYou: true,
        undoSwipe: true,
        priorityRecommendations: true,
        premiumBadge: true,
        noAds: true,
        fullStatistics: true,
        prioritySupport: true,
      );
}

/// User subscription status
class UserSubscription {
  final String userId;
  final String planId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;

  UserSubscription({
    required this.userId,
    required this.planId,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      userId: map['userId'] as String,
      planId: map['planId'] as String,
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null,
      isActive: map['isActive'] as bool? ?? false,
      stripeSubscriptionId: map['stripeSubscriptionId'] as String?,
      stripeCustomerId: map['stripeCustomerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isActive': isActive,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripeCustomerId': stripeCustomerId,
    };
  }

  UserLimits get limits => UserLimits.fromPlan(planId);

  bool get isPremium => planId == 'premium' && isActive;
  bool get isBasic => planId == 'basic' || !isActive;
}
