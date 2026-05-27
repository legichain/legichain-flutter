/// AML / sanctions screening response models.
library;

enum ScreeningRecommendation { clear, review, block }

ScreeningRecommendation _recFrom(String? s) => switch (s) {
      'clear' => ScreeningRecommendation.clear,
      'review' => ScreeningRecommendation.review,
      'block' => ScreeningRecommendation.block,
      _ => ScreeningRecommendation.clear,
    };

enum RiskLevel { none, low, medium, high, critical }

RiskLevel _riskFrom(String? s) => switch (s) {
      'no' || 'none' => RiskLevel.none,
      'low' => RiskLevel.low,
      'medium' => RiskLevel.medium,
      'high' => RiskLevel.high,
      'critical' => RiskLevel.critical,
      _ => RiskLevel.none,
    };

class HitFlags {
  final bool isSanctioned;
  final bool isPep;
  final bool isWanted;
  final bool isCrime;
  final bool isAdverseMedia;
  const HitFlags({
    this.isSanctioned = false,
    this.isPep = false,
    this.isWanted = false,
    this.isCrime = false,
    this.isAdverseMedia = false,
  });
  factory HitFlags.fromJson(Map<String, dynamic> j) => HitFlags(
        isSanctioned: j['is_sanctioned'] == true,
        isPep: j['is_pep'] == true,
        isWanted: j['is_wanted'] == true,
        isCrime: j['is_crime'] == true,
        isAdverseMedia: j['is_adverse_media'] == true,
      );
}

class Hit {
  final String entityId;
  final String canonicalId;
  final String? caption;
  /// Show this 0..100 number to the user, not [score].
  final int matchConfidence;
  /// Legacy 0..10 raw match strength. Internal use.
  final int score;
  final int riskScore;
  final RiskLevel riskLevel;
  final String riskSource;
  final List<String> topics;
  final List<String> sources;
  final List<String> countries;
  final List<String> matchSignals;
  final HitFlags flags;

  const Hit({
    required this.entityId,
    required this.canonicalId,
    this.caption,
    required this.matchConfidence,
    required this.score,
    required this.riskScore,
    required this.riskLevel,
    required this.riskSource,
    required this.topics,
    required this.sources,
    required this.countries,
    required this.matchSignals,
    required this.flags,
  });

  factory Hit.fromJson(Map<String, dynamic> j) => Hit(
        entityId: j['entity_id'] as String? ?? '',
        canonicalId: j['canonical_id'] as String? ?? '',
        caption: j['caption'] as String?,
        matchConfidence: (j['match_confidence'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toInt() ?? 0,
        riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
        riskLevel: _riskFrom(j['risk_level'] as String?),
        riskSource: j['risk_source'] as String? ?? '',
        topics: List<String>.from(j['topics'] as List? ?? const []),
        sources: List<String>.from(j['sources'] as List? ?? const []),
        countries: List<String>.from(j['countries'] as List? ?? const []),
        matchSignals: List<String>.from(j['match_signals'] as List? ?? const []),
        flags: HitFlags.fromJson(
            (j['flags'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

class ScreeningSummary {
  final bool matched;
  final int hitCount;
  final bool hasSanctioned;
  final bool hasPep;
  final bool hasWanted;
  final bool hasCrime;
  final bool hasAdverseMedia;
  final int topRiskScore;
  final RiskLevel topRiskLevel;
  final int topMatchConfidence;
  final ScreeningRecommendation recommendation;
  final List<String> authorities;
  final List<String> sources;

  const ScreeningSummary({
    required this.matched,
    required this.hitCount,
    required this.hasSanctioned,
    required this.hasPep,
    required this.hasWanted,
    required this.hasCrime,
    required this.hasAdverseMedia,
    required this.topRiskScore,
    required this.topRiskLevel,
    required this.topMatchConfidence,
    required this.recommendation,
    required this.authorities,
    required this.sources,
  });

  factory ScreeningSummary.fromJson(Map<String, dynamic> j) => ScreeningSummary(
        matched: j['matched'] == true,
        hitCount: (j['hit_count'] as num?)?.toInt() ?? 0,
        hasSanctioned: j['has_sanctioned_hit'] == true,
        hasPep: j['has_pep_hit'] == true,
        hasWanted: j['has_wanted_hit'] == true,
        hasCrime: j['has_crime_hit'] == true,
        hasAdverseMedia: j['has_adverse_media_hit'] == true,
        topRiskScore: (j['top_risk_score'] as num?)?.toInt() ?? 0,
        topRiskLevel: _riskFrom(j['top_risk_level'] as String?),
        topMatchConfidence: (j['top_match_confidence'] as num?)?.toInt() ?? 0,
        recommendation: _recFrom(j['recommendation'] as String?),
        authorities: List<String>.from(j['authorities'] as List? ?? const []),
        sources: List<String>.from(j['sources'] as List? ?? const []),
      );
}

class ScreeningResponse {
  final String requestId;
  final String? screeningId;
  final bool matched;
  final ScreeningSummary summary;
  final List<Hit> hits;
  final int searchTimeMs;
  final int costCredits;
  final int creditsRemaining;

  const ScreeningResponse({
    required this.requestId,
    this.screeningId,
    required this.matched,
    required this.summary,
    required this.hits,
    required this.searchTimeMs,
    required this.costCredits,
    required this.creditsRemaining,
  });

  factory ScreeningResponse.fromJson(Map<String, dynamic> j) =>
      ScreeningResponse(
        requestId: j['request_id'] as String? ?? '',
        screeningId: j['screening_id'] as String?,
        matched: j['matched'] == true,
        summary: ScreeningSummary.fromJson(
            (j['summary'] as Map?)?.cast<String, dynamic>() ?? const {}),
        hits: ((j['hits'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Hit.fromJson)
            .toList(),
        searchTimeMs: (j['search_time_ms'] as num?)?.toInt() ?? 0,
        costCredits: (j['cost_credits'] as num?)?.toInt() ?? 0,
        creditsRemaining: (j['credits_remaining'] as num?)?.toInt() ?? 0,
      );
}
