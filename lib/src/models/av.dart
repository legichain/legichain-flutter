/// Address verification models.
library;

class ClaimedAddress {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;

  /// ISO 3166-1 alpha-2 or alpha-3 (server accepts both).
  final String country;

  const ClaimedAddress({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'country': country};
    if (line1 != null) m['line1'] = line1;
    if (line2 != null) m['line2'] = line2;
    if (city != null) m['city'] = city;
    if (state != null) m['state'] = state;
    if (postalCode != null) m['postal_code'] = postalCode;
    return m;
  }
}

enum AVDocumentType {
  utilityBill,
  bankStatement,
  govLetter,
  telcoBill,
  residencyCertificate,
  taxLetter,
}

extension AVDocumentTypeWire on AVDocumentType {
  String get wire => switch (this) {
        AVDocumentType.utilityBill => 'utility_bill',
        AVDocumentType.bankStatement => 'bank_statement',
        AVDocumentType.govLetter => 'gov_letter',
        AVDocumentType.telcoBill => 'telco_bill',
        AVDocumentType.residencyCertificate => 'residency_certificate',
        AVDocumentType.taxLetter => 'tax_letter',
      };
}

class AVCreate {
  final String? externalReference;
  final String? subjectExternalId;
  final String? personaId;
  final ClaimedAddress claimedAddress;
  final List<AVDocumentType> acceptedDocumentTypes;
  final int maxAgeDays;
  final String? callbackUrl;

  const AVCreate({
    this.externalReference,
    this.subjectExternalId,
    this.personaId,
    required this.claimedAddress,
    this.acceptedDocumentTypes = const [
      AVDocumentType.utilityBill,
      AVDocumentType.bankStatement,
    ],
    this.maxAgeDays = 90,
    this.callbackUrl,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'claimed_address': claimedAddress.toJson(),
      'accepted_document_types':
          acceptedDocumentTypes.map((d) => d.wire).toList(),
      'max_age_days': maxAgeDays,
    };
    if (externalReference != null) m['external_reference'] = externalReference;
    if (subjectExternalId != null) m['subject_external_id'] = subjectExternalId;
    if (personaId != null) m['persona_id'] = personaId;
    if (callbackUrl != null) m['callback_url'] = callbackUrl;
    return m;
  }
}

class AVCreated {
  final String verificationId;
  final String personaId;
  final String state;
  final String clientToken;
  final DateTime? clientTokenExpiresAt;
  final DateTime expiresAt;
  const AVCreated({
    required this.verificationId,
    required this.personaId,
    required this.state,
    required this.clientToken,
    this.clientTokenExpiresAt,
    required this.expiresAt,
  });
  factory AVCreated.fromJson(Map<String, dynamic> j) => AVCreated(
        verificationId: j['verification_id'] as String,
        personaId: j['persona_id'] as String,
        state: j['state'] as String,
        clientToken: j['client_token'] as String,
        clientTokenExpiresAt: j['client_token_expires_at'] is String
            ? DateTime.parse(j['client_token_expires_at'])
            : null,
        expiresAt: DateTime.parse(j['expires_at'] as String),
      );
}

class AVProofUploaded {
  final String proofId;
  final String state;
  final String extractionStatus;
  final String? parsedIssuer;
  final DateTime? parsedIssuedAt;
  final String? parsedAddress;
  const AVProofUploaded({
    required this.proofId,
    required this.state,
    required this.extractionStatus,
    this.parsedIssuer,
    this.parsedIssuedAt,
    this.parsedAddress,
  });
  factory AVProofUploaded.fromJson(Map<String, dynamic> j) => AVProofUploaded(
        proofId: j['proof_id'] as String,
        state: j['state'] as String,
        extractionStatus: j['extraction_status'] as String,
        parsedIssuer: j['parsed_issuer'] as String?,
        parsedIssuedAt: j['parsed_issued_at'] is String
            ? DateTime.tryParse(j['parsed_issued_at'])
            : null,
        parsedAddress: j['parsed_address'] as String?,
      );
}

class AVStatus {
  final String verificationId;
  final String personaId;
  final String state;
  final int currentAttempt;
  final int maxAttempts;
  final double? matchConfidence;
  final String? outcome;
  final String? outcomeReason;
  final List<Map<String, dynamic>> proofs;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final DateTime requestedAt;

  const AVStatus({
    required this.verificationId,
    required this.personaId,
    required this.state,
    required this.currentAttempt,
    required this.maxAttempts,
    this.matchConfidence,
    this.outcome,
    this.outcomeReason,
    this.proofs = const [],
    this.completedAt,
    required this.expiresAt,
    required this.requestedAt,
  });

  factory AVStatus.fromJson(Map<String, dynamic> j) => AVStatus(
        verificationId: j['verification_id'] as String,
        personaId: j['persona_id'] as String,
        state: j['state'] as String,
        currentAttempt: (j['current_attempt'] as num?)?.toInt() ?? 0,
        maxAttempts: (j['max_attempts'] as num?)?.toInt() ?? 3,
        matchConfidence: (j['match_confidence'] as num?)?.toDouble(),
        outcome: j['outcome'] as String?,
        outcomeReason: j['outcome_reason'] as String?,
        proofs: ((j['proofs'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
        completedAt: j['completed_at'] is String
            ? DateTime.tryParse(j['completed_at'])
            : null,
        expiresAt: DateTime.parse(j['expires_at'] as String),
        requestedAt: DateTime.parse(j['requested_at'] as String),
      );
}
