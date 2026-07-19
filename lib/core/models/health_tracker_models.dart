// Models for Phase 3 Health Trackers

// Base model for health tracker logs
abstract class HealthTrackerLog {
  final String? id;
  final DateTime timestamp;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HealthTrackerLog({
    this.id,
    required this.timestamp,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson();
}

/// Hydration Tracker Models
class HydrationLog extends HealthTrackerLog {
  final int amountMl;
  final String type; // "water", "electrolyte", "other"
  final String timezone;
  final String source; // manual|ai|doctor|system

  final Map<String, dynamic>? sourceMeta;
  final HydrationAiMeta? ai;

  final String? correlationId;
  final String? eventId;

  HydrationLog({
    super.id,
    required super.timestamp,
    required this.amountMl,
    this.type = 'water',
    this.timezone = 'UTC',
    this.source = 'manual',
    super.notes,
    super.createdAt,
    super.updatedAt,
    this.sourceMeta,
    this.ai,
    this.correlationId,
    this.eventId,
  });

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    return HydrationLog(
      id: json['_id']?.toString(),
      amountMl: (json['amountMl'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'water',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      notes: json['notes']?.toString(),
      timezone: json['timezone']?.toString() ?? 'UTC',
      source: json['source']?.toString() ?? 'manual',
      sourceMeta: json['sourceMeta'] is Map
          ? (json['sourceMeta'] as Map).cast<String, dynamic>()
          : null,
      ai: json['ai'] is Map
          ? HydrationAiMeta.fromJson(
              (json['ai'] as Map).cast<String, dynamic>(),
            )
          : null,
      correlationId: json['correlationId']?.toString(),
      eventId: json['eventId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'amountMl': amountMl,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'timezone': timezone,
      'source': source,
      if (notes != null) 'notes': notes,
      if (sourceMeta != null) 'sourceMeta': sourceMeta,
      if (ai != null) 'ai': ai!.toJson(),
      if (correlationId != null) 'correlationId': correlationId,
      if (eventId != null) 'eventId': eventId,
    };
  }
}

class HydrationAiMeta {
  final bool? needsProcessing;
  final String? processingStatus;
  final DateTime? processedAt;
  final String? lastError;
  final String? modelVersion;
  final Map<String, dynamic>? features;

  const HydrationAiMeta({
    this.needsProcessing,
    this.processingStatus,
    this.processedAt,
    this.lastError,
    this.modelVersion,
    this.features,
  });

  factory HydrationAiMeta.fromJson(Map<String, dynamic> json) {
    return HydrationAiMeta(
      needsProcessing: json['needsProcessing'] as bool?,
      processingStatus: json['processingStatus']?.toString(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'].toString())
          : null,
      lastError: json['lastError']?.toString(),
      modelVersion: json['modelVersion']?.toString(),
      features: json['features'] is Map
          ? (json['features'] as Map).cast<String, dynamic>()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (needsProcessing != null) 'needsProcessing': needsProcessing,
      if (processingStatus != null) 'processingStatus': processingStatus,
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (lastError != null) 'lastError': lastError,
      if (modelVersion != null) 'modelVersion': modelVersion,
      if (features != null) 'features': features,
    };
  }
}

/// Sleep Tracker Models
class SleepLog extends HealthTrackerLog {
  final DateTime sleepStartTime;
  final DateTime sleepEndTime;
  final int durationMinutes;
  final int qualityScore; // 1-5
  final String source; // "manual" or "device"

  SleepLog({
    super.id,
    required this.sleepStartTime,
    required this.sleepEndTime,
    required this.durationMinutes,
    this.qualityScore = 3,
    this.source = 'manual',
    super.notes,
    super.createdAt,
    super.updatedAt,
  }) : super(timestamp: sleepStartTime);

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['_id']?.toString(),
      sleepStartTime: json['sleepStartTime'] != null
          ? DateTime.parse(json['sleepStartTime'])
          : DateTime.now(),
      sleepEndTime: json['sleepEndTime'] != null
          ? DateTime.parse(json['sleepEndTime'])
          : DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      qualityScore: (json['qualityScore'] as num?)?.toInt() ?? 3,
      source: json['source']?.toString() ?? 'manual',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'sleepStartTime': sleepStartTime.toIso8601String(),
      'sleepEndTime': sleepEndTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'qualityScore': qualityScore,
      'source': source,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Symptom Tracker Models
class SymptomLog extends HealthTrackerLog {
  final String symptomName;
  final int severity; // 1-10
  final double durationHours;
  final String source; // "manual" or "device"

  SymptomLog({
    super.id,
    required super.timestamp,
    required this.symptomName,
    required this.severity,
    required this.durationHours,
    this.source = 'manual',
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['_id']?.toString(),
      symptomName: json['symptomName']?.toString() ?? '',
      severity: (json['severity'] as num?)?.toInt() ?? 1,
      durationHours: (json['durationHours'] as num?)?.toDouble() ?? 0.0,
      source: json['source']?.toString() ?? 'manual',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'symptomName': symptomName,
      'severity': severity,
      'durationHours': durationHours,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Medication Tracker Models
class MedicationLog extends HealthTrackerLog {
  final String medicationName;
  final double dosage;
  final String dosageUnit; // "mg", "ml", etc.
  final DateTime takenAt;
  final String? prescribedBy;

  MedicationLog({
    super.id,
    required this.medicationName,
    required this.dosage,
    required this.dosageUnit,
    required this.takenAt,
    this.prescribedBy,
    super.notes,
    super.createdAt,
    super.updatedAt,
  }) : super(timestamp: takenAt);

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['_id']?.toString(),
      medicationName: json['medicationName']?.toString() ?? '',
      dosage: (json['dosage'] as num?)?.toDouble() ?? 0.0,
      dosageUnit: json['dosageUnit']?.toString() ?? 'mg',
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'])
          : DateTime.now(),
      prescribedBy: json['prescribedBy']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'medicationName': medicationName,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'takenAt': takenAt.toIso8601String(),
      if (prescribedBy != null) 'prescribedBy': prescribedBy,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Supplement Tracker Models
class SupplementLog extends HealthTrackerLog {
  final String supplementName;
  final String? brand;
  final double dosage;
  final String dosageUnit; // "IU", "mg", etc.
  final DateTime takenAt;

  SupplementLog({
    super.id,
    required this.supplementName,
    this.brand,
    required this.dosage,
    required this.dosageUnit,
    required this.takenAt,
    super.notes,
    super.createdAt,
    super.updatedAt,
  }) : super(timestamp: takenAt);

  factory SupplementLog.fromJson(Map<String, dynamic> json) {
    return SupplementLog(
      id: json['_id']?.toString(),
      supplementName: json['supplementName']?.toString() ?? '',
      brand: json['brand']?.toString(),
      dosage: (json['dosage'] as num?)?.toDouble() ?? 0.0,
      dosageUnit: json['dosageUnit']?.toString() ?? 'IU',
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'])
          : DateTime.now(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'supplementName': supplementName,
      if (brand != null) 'brand': brand,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'takenAt': takenAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Baby Growth Tracker Models (Phase 3)
class BabyGrowthLog extends HealthTrackerLog {
  final String? babyId;
  final double? weightKg;
  final double? heightCm;
  final double? headCircumferenceCm;
  final DateTime measurementDate;

  BabyGrowthLog({
    super.id,
    this.babyId,
    this.weightKg,
    this.heightCm,
    this.headCircumferenceCm,
    required this.measurementDate,
    super.notes,
    super.createdAt,
    super.updatedAt,
  }) : super(timestamp: measurementDate);

  factory BabyGrowthLog.fromJson(Map<String, dynamic> json) {
    return BabyGrowthLog(
      id: json['_id']?.toString(),
      babyId: json['babyId']?.toString(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      headCircumferenceCm: (json['headCircumferenceCm'] as num?)?.toDouble(),
      measurementDate: json['measurementDate'] != null
          ? DateTime.parse(json['measurementDate'])
          : DateTime.now(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (babyId != null) 'babyId': babyId,
      if (weightKg != null) 'weightKg': weightKg,
      if (heightCm != null) 'heightCm': heightCm,
      if (headCircumferenceCm != null)
        'headCircumferenceCm': headCircumferenceCm,
      'measurementDate': measurementDate.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Postpartum Recovery Tracker Model
class PostpartumLog extends HealthTrackerLog {
  final int painScore; // 1-5
  final int woundHealingScore; // 1-5
  final int swellingScore; // 1-5
  final int mobilityScore; // 1-5
  final int energyScore; // 1-5
  final int strengthScore; // 1-5

  // Clinical Alert fields (Nested)
  final PostpartumPhysical? physical;
  final PostpartumUterine? uterine;
  final PostpartumEnergy? energy;

  // Legacy fields for compatibility
  final int pain; // 0-10
  final String woundHealing; // "poor", "okay", "good"
  final String swelling; // "high", "mild", "none"
  final String mobility; // "limited", "moderate", "normal"
  final String cramps; // "severe", "mild", "none"
  final String bellyReduction; // "no_change", "slow", "good_progress"
  final String energyLevel; // "low", "moderate", "high"
  final String fatigue; // "high", "medium", "low"
  final String dailyActivity; // "limited", "moderate", "normal"

  PostpartumLog({
    super.id,
    required super.timestamp,
    required this.painScore,
    required this.woundHealingScore,
    required this.swellingScore,
    required this.mobilityScore,
    required this.energyScore,
    required this.strengthScore,
    this.physical,
    this.uterine,
    this.energy,
    this.pain = 0,
    this.woundHealing = 'okay',
    this.swelling = 'none',
    this.mobility = 'normal',
    this.cramps = 'none',
    this.bellyReduction = 'slow',
    this.energyLevel = 'moderate',
    this.fatigue = 'medium',
    this.dailyActivity = 'normal',
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory PostpartumLog.fromJson(Map<String, dynamic> json) {
    return PostpartumLog(
      id: json['_id']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      painScore: (json['painScore'] as num?)?.toInt() ?? 3,
      woundHealingScore: (json['woundHealingScore'] as num?)?.toInt() ?? 3,
      swellingScore: (json['swellingScore'] as num?)?.toInt() ?? 3,
      mobilityScore: (json['mobilityScore'] as num?)?.toInt() ?? 3,
      energyScore: (json['energyScore'] as num?)?.toInt() ?? 3,
      strengthScore: (json['strengthScore'] as num?)?.toInt() ?? 3,
      
      physical: json['physical'] != null ? PostpartumPhysical.fromJson(json['physical']) : null,
      uterine: json['uterine'] != null ? PostpartumUterine.fromJson(json['uterine']) : null,
      energy: json['energy'] != null ? PostpartumEnergy.fromJson(json['energy']) : null,

      pain: (json['pain'] as num?)?.toInt() ?? 0,
      woundHealing: json['woundHealing']?.toString() ?? 'okay',
      swelling: json['swelling']?.toString() ?? 'none',
      mobility: json['mobility']?.toString() ?? 'normal',
      cramps: json['cramps']?.toString() ?? 'none',
      bellyReduction: json['bellyReduction']?.toString() ?? 'slow',
      energyLevel: json['energyLevel']?.toString() ?? 'moderate',
      fatigue: json['fatigue']?.toString() ?? 'medium',
      dailyActivity: json['dailyActivity']?.toString() ?? 'normal',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'timestamp': timestamp.toIso8601String(),
      'painScore': painScore,
      'woundHealingScore': woundHealingScore,
      'swellingScore': swellingScore,
      'mobilityScore': mobilityScore,
      'energyScore': energyScore,
      'strengthScore': strengthScore,
      
      // Clinical Alert Intelligence structure
      if (physical != null) 'physical': physical!.toJson(),
      if (uterine != null) 'uterine': uterine!.toJson(),
      if (energy != null) 'energy': energy!.toJson(),

      'pain': pain,
      'woundHealing': woundHealing,
      'swelling': swelling,
      'mobility': mobility,
      'cramps': cramps,
      'bellyReduction': bellyReduction,
      'energyLevel': energyLevel,
      'fatigue': fatigue,
      'dailyActivity': dailyActivity,
      if (notes != null) 'notes': notes,
    };
  }

  /// Calculates Physical Healing Score / 100 based on 1-5 scales
  double get physicalHealingScore {
    // painScore (1-5): 1 is best (no pain), 5 is worst
    // others (1-5): 5 is best, 1 is worst
    double p = (6 - painScore).toDouble(); // Invert pain
    double w = woundHealingScore.toDouble();
    double s = swellingScore.toDouble();
    double m = mobilityScore.toDouble();
    return (p + w + s + m) / 20.0 * 100.0;
  }

  /// Calculates Energy / 100 based on 1-5 scales
  double get energyScorePercent {
    return (energyScore + strengthScore) / 10.0 * 100.0;
  }

  /// Calculates Uterine Recovery Score / 100
  double get uterineRecoveryScore {
    double score = 0;

    // Cramps (50 points)
    switch (cramps.toLowerCase()) {
      case 'none':
        score += 50;
        break;
      case 'mild':
        score += 25;
        break;
      case 'severe':
        score += 0;
        break;
    }

    // Belly reduction (50 points)
    switch (bellyReduction.toLowerCase()) {
      case 'good_progress':
      case 'good progress':
        score += 50;
        break;
      case 'slow':
        score += 25;
        break;
      case 'no_change':
      case 'no change':
        score += 0;
        break;
    }

    return score;
  }

  /// Calculates Energy & Strength Score / 100 based on 1-5 scales
  double get energyStrengthScore {
    // energyScore (1-5): 5 is best
    // strengthScore (1-5): 5 is best
    double e = energyScore.toDouble();
    double s = strengthScore.toDouble();

    return (e + s) / 10.0 * 100.0;
  }

  /// Overall Recovery Status based on scores
  String get physicalHealingStatus {
    final score = physicalHealingScore;
    if (score >= 80) return 'Recovering well';
    if (score >= 50) return 'Needs attention';
    return 'Alert';
  }

  String get uterineRecoveryStatus {
    final score = uterineRecoveryScore;
    if (score >= 80) return 'Normal recovery';
    if (score >= 50) return 'Delayed';
    return 'Needs attention';
  }

  String get energyStrengthStatus {
    final score = energyStrengthScore;
    if (score >= 80) return 'Strong recovery';
    if (score >= 50) return 'Low energy';
    return 'High fatigue';
  }
}

class PostpartumPhysical {
  final int pain; // 1-10
  final int woundHealing; // 1-5
  final String swelling; // Enum: ["none", "mild", "moderate", "severe"]

  PostpartumPhysical({
    required this.pain,
    required this.woundHealing,
    required this.swelling,
  });

  factory PostpartumPhysical.fromJson(Map<String, dynamic> json) {
    return PostpartumPhysical(
      pain: (json['pain'] as num?)?.toInt() ?? 0,
      woundHealing: (json['woundHealing'] as num?)?.toInt() ?? 0,
      swelling: json['swelling']?.toString() ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
    'pain': pain,
    'woundHealing': woundHealing,
    'swelling': swelling,
  };
}

class PostpartumUterine {
  final int bleedingLevel; // 1-5
  final String cramps; // Enum: ["none", "mild", "moderate", "severe"]

  PostpartumUterine({
    required this.bleedingLevel,
    required this.cramps,
  });

  factory PostpartumUterine.fromJson(Map<String, dynamic> json) {
    return PostpartumUterine(
      bleedingLevel: (json['bleedingLevel'] as num?)?.toInt() ?? 0,
      cramps: json['cramps']?.toString() ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
    'bleedingLevel': bleedingLevel,
    'cramps': cramps,
  };
}

class PostpartumEnergy {
  final String energyLevel; // Enum: ["low", "medium", "high"]
  final String fatigue; // Enum: ["low", "medium", "high"]
  final int sleepQuality; // 1-5

  PostpartumEnergy({
    required this.energyLevel,
    required this.fatigue,
    required this.sleepQuality,
  });

  factory PostpartumEnergy.fromJson(Map<String, dynamic> json) {
    return PostpartumEnergy(
      energyLevel: json['energyLevel']?.toString() ?? 'medium',
      fatigue: json['fatigue']?.toString() ?? 'medium',
      sleepQuality: (json['sleepQuality'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'energyLevel': energyLevel,
    'fatigue': fatigue,
    'sleepQuality': sleepQuality,
  };
}

/// Paginated Response Model
class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginatedResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final dataField = json['data'];
    final pagination = () {
      if (dataField is Map<String, dynamic>) {
        final p = dataField['pagination'];
        if (p is Map) return p.cast<String, dynamic>();
      }
      final p2 = json['pagination'];
      if (p2 is Map) return p2.cast<String, dynamic>();
      return <String, dynamic>{};
    }();

    final dataList = () {
      if (dataField is Map<String, dynamic>) {
        final items = dataField['items'];
        if (items is List) return items;
        return <dynamic>[];
      }
      if (dataField is List<dynamic>) {
        return dataField;
      }
      return <dynamic>[];
    }();

    return PaginatedResponse<T>(
      data: dataList
          .map((item) => fromJsonT((item as Map).cast<String, dynamic>()))
          .toList(),
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: pagination['hasNext'] == true,
      hasPrev: pagination['hasPrev'] == true,
    );
  }
}
