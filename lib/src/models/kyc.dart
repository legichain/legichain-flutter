/// KYC request + response models.
library;

import 'common.dart';

class KycApplicationCreate {
  final String? subjectExternalId;
  final String? personaId;
  final String? externalReference;
  final Intent intent;
  final List<DocumentType> documentTypeAllowed;
  final bool nfcRequired;
  final bool? livenessRequired;
  final bool? faceMatchRequired;
  final String? callbackUrl;
  final String? claimedFullName;
  final String? claimedPersonalNumber;
  final DateTime? claimedBirthDate;
  final DateTime? claimedExpiryDate;
  final String? claimedDocumentNumber;
  final String? claimedNationality;
  final String? claimedIssuingCountry;
  final Sex? claimedSex;
  final DocumentType? claimedDocumentType;
  final Map<String, dynamic> meta;

  const KycApplicationCreate({
    this.subjectExternalId,
    this.personaId,
    this.externalReference,
    this.intent = Intent.onboarding,
    this.documentTypeAllowed = const [
      DocumentType.trIdCard,
      DocumentType.passport,
    ],
    this.nfcRequired = false,
    this.livenessRequired,
    this.faceMatchRequired,
    this.callbackUrl,
    this.claimedFullName,
    this.claimedPersonalNumber,
    this.claimedBirthDate,
    this.claimedExpiryDate,
    this.claimedDocumentNumber,
    this.claimedNationality,
    this.claimedIssuingCountry,
    this.claimedSex,
    this.claimedDocumentType,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'intent': intent.wire,
      'document_type_allowed':
          documentTypeAllowed.map((d) => d.wire).toList(),
      'nfc_required': nfcRequired,
      if (livenessRequired != null) 'liveness_required': livenessRequired,
      if (faceMatchRequired != null) 'face_match_required': faceMatchRequired,
      'meta': meta,
    };
    if (subjectExternalId != null) m['subject_external_id'] = subjectExternalId;
    if (personaId != null) m['persona_id'] = personaId;
    if (externalReference != null) m['external_reference'] = externalReference;
    if (callbackUrl != null) m['callback_url'] = callbackUrl;
    if (claimedFullName != null) m['claimed_full_name'] = claimedFullName;
    if (claimedPersonalNumber != null) {
      m['claimed_personal_number'] = claimedPersonalNumber;
    }
    if (claimedBirthDate != null) {
      m['claimed_birth_date'] = _isoDate(claimedBirthDate!);
    }
    if (claimedExpiryDate != null) {
      m['claimed_expiry_date'] = _isoDate(claimedExpiryDate!);
    }
    if (claimedDocumentNumber != null) {
      m['claimed_document_number'] = claimedDocumentNumber;
    }
    if (claimedNationality != null) m['claimed_nationality'] = claimedNationality;
    if (claimedIssuingCountry != null) {
      m['claimed_issuing_country'] = claimedIssuingCountry;
    }
    if (claimedSex != null) m['claimed_sex'] = claimedSex!.wire;
    if (claimedDocumentType != null) {
      m['claimed_document_type'] = claimedDocumentType!.wire;
    }
    return m;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class KycApplicationCreated {
  final String applicationId;
  final String personaId;
  final bool personaCreated;
  final String clientToken;
  final DateTime? clientTokenExpiresAt;
  final String state;
  final List<String> nextSteps;
  final DateTime expiresAt;

  const KycApplicationCreated({
    required this.applicationId,
    required this.personaId,
    required this.personaCreated,
    required this.clientToken,
    this.clientTokenExpiresAt,
    required this.state,
    required this.nextSteps,
    required this.expiresAt,
  });

  factory KycApplicationCreated.fromJson(Map<String, dynamic> j) =>
      KycApplicationCreated(
        applicationId: j['application_id'] as String,
        personaId: j['persona_id'] as String,
        personaCreated: j['persona_created'] == true,
        clientToken: j['client_token'] as String,
        clientTokenExpiresAt: _parseDate(j['client_token_expires_at']),
        state: j['state'] as String,
        nextSteps: List<String>.from(j['next_steps'] as List? ?? const []),
        expiresAt: _parseDate(j['expires_at'])!,
      );
}

class KycStatus {
  final String applicationId;
  final String personaId;
  final String state;
  final KycCurrentStep currentStep;
  final bool retryAvailable;
  final int currentAttempt;
  final int maxAttempts;
  final double? riskScore;
  final KycDecisionSummary? decision;
  final Map<String, dynamic>? extractedFields;
  final Map<String, dynamic>? extractedFieldsBySource;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final DateTime requestedAt;

  const KycStatus({
    required this.applicationId,
    required this.personaId,
    required this.state,
    required this.currentStep,
    required this.retryAvailable,
    required this.currentAttempt,
    required this.maxAttempts,
    this.riskScore,
    this.decision,
    this.extractedFields,
    this.extractedFieldsBySource,
    this.completedAt,
    required this.expiresAt,
    required this.requestedAt,
  });

  bool get isTerminal => currentStep.isTerminal;

  factory KycStatus.fromJson(Map<String, dynamic> j) => KycStatus(
        applicationId: j['application_id'] as String,
        personaId: j['persona_id'] as String,
        state: j['state'] as String,
        currentStep: KycCurrentStepWire.from(j['current_step'] as String?),
        retryAvailable: j['retry_available'] == true,
        currentAttempt: (j['current_attempt'] as num?)?.toInt() ?? 0,
        maxAttempts: (j['max_attempts'] as num?)?.toInt() ?? 3,
        riskScore: (j['risk_score'] as num?)?.toDouble(),
        decision: j['decision'] == null
            ? null
            : KycDecisionSummary.fromJson(
                (j['decision'] as Map).cast<String, dynamic>()),
        extractedFields:
            (j['extracted_fields'] as Map?)?.cast<String, dynamic>(),
        extractedFieldsBySource:
            (j['extracted_fields_by_source'] as Map?)?.cast<String, dynamic>(),
        completedAt: _parseDate(j['completed_at']),
        expiresAt: _parseDate(j['expires_at'])!,
        requestedAt: _parseDate(j['requested_at'])!,
      );
}

class KycDecisionSummary {
  final DecisionOutcome? outcome;
  final String? outcomeReason;
  final String? decisionId;
  final double? riskScore;
  const KycDecisionSummary({
    this.outcome,
    this.outcomeReason,
    this.decisionId,
    this.riskScore,
  });
  factory KycDecisionSummary.fromJson(Map<String, dynamic> j) =>
      KycDecisionSummary(
        outcome: DecisionOutcomeWire.from(j['outcome'] as String?),
        outcomeReason: j['outcome_reason'] as String?,
        decisionId: j['decision_id'] as String?,
        riskScore: (j['risk_score'] as num?)?.toDouble(),
      );
}

class DocumentSubmitResponse {
  final String documentId;
  final String imageId;
  final String state;
  final bool iqaPassed;
  final String? iqaReason;
  final double? blurLaplacian;
  final double? glareScore;
  final String extractionStatus;
  const DocumentSubmitResponse({
    required this.documentId,
    required this.imageId,
    required this.state,
    required this.iqaPassed,
    this.iqaReason,
    this.blurLaplacian,
    this.glareScore,
    required this.extractionStatus,
  });
  factory DocumentSubmitResponse.fromJson(Map<String, dynamic> j) =>
      DocumentSubmitResponse(
        documentId: j['document_id'] as String,
        imageId: j['image_id'] as String,
        state: j['state'] as String,
        iqaPassed: j['iqa_passed'] == true,
        iqaReason: j['iqa_reason'] as String?,
        blurLaplacian: (j['blur_laplacian'] as num?)?.toDouble(),
        glareScore: (j['glare_score'] as num?)?.toDouble(),
        extractionStatus: j['extraction_status'] as String,
      );
}

class NfcSubmitResponse {
  final String nfcReadId;
  final String state;
  final String verificationStatus;
  final bool? passiveAuthPassed;
  final bool? certChainValid;
  final String? cscaCountry;
  final Map<String, bool> dgHashResults;
  final List<String> failureCodes;
  const NfcSubmitResponse({
    required this.nfcReadId,
    required this.state,
    required this.verificationStatus,
    this.passiveAuthPassed,
    this.certChainValid,
    this.cscaCountry,
    this.dgHashResults = const {},
    this.failureCodes = const [],
  });
  factory NfcSubmitResponse.fromJson(Map<String, dynamic> j) => NfcSubmitResponse(
        nfcReadId: j['nfc_read_id'] as String,
        state: j['state'] as String,
        verificationStatus: j['verification_status'] as String,
        passiveAuthPassed: j['passive_auth_passed'] as bool?,
        certChainValid: j['cert_chain_valid'] as bool?,
        cscaCountry: j['csca_country'] as String?,
        dgHashResults: ((j['dg_hash_results'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), v == true)),
        failureCodes: List<String>.from(j['failure_codes'] as List? ?? const []),
      );
}

class LivenessChallenge {
  final String applicationId;
  final String challengeToken;
  final List<String> sequence;
  final DateTime issuedAt;
  final DateTime validUntil;
  const LivenessChallenge({
    required this.applicationId,
    required this.challengeToken,
    required this.sequence,
    required this.issuedAt,
    required this.validUntil,
  });
  factory LivenessChallenge.fromJson(Map<String, dynamic> j) =>
      LivenessChallenge(
        applicationId: j['application_id'] as String,
        challengeToken: j['challenge_token'] as String,
        sequence: List<String>.from(j['sequence'] as List),
        issuedAt: _parseDate(j['issued_at'])!,
        validUntil: _parseDate(j['valid_until'])!,
      );
}

class KycDecision {
  final String applicationId;
  final String personaId;
  final DecisionOutcome? outcome;
  final bool pending;
  final String? state;
  final String? outcomeReason;
  final double? riskScore;
  final String? decisionId;
  final List<String> hardFailCodes;
  final String? manualReviewId;
  final String? manualReviewPriority;
  final DateTime? completedAt;
  const KycDecision({
    required this.applicationId,
    required this.personaId,
    required this.outcome,
    this.pending = false,
    this.state,
    this.outcomeReason,
    this.riskScore,
    required this.decisionId,
    this.hardFailCodes = const [],
    this.manualReviewId,
    this.manualReviewPriority,
    this.completedAt,
  });
  factory KycDecision.fromJson(Map<String, dynamic> j) => KycDecision(
        applicationId: j['application_id'] as String,
        personaId: j['persona_id'] as String,
        outcome: DecisionOutcomeWire.from(j['outcome'] as String?),
        outcomeReason: j['outcome_reason'] as String?,
        riskScore: (j['risk_score'] as num?)?.toDouble(),
        decisionId: j['decision_id'] as String?,
        pending: j['pending'] == true, state: j['state'] as String?,
        hardFailCodes:
            List<String>.from(j['hard_fail_codes'] as List? ?? const []),
        manualReviewId: j['manual_review_id'] as String?,
        manualReviewPriority: j['manual_review_priority'] as String?,
        completedAt: _parseDate(j['completed_at']),
      );
}

DateTime? _parseDate(dynamic v) =>
    v is String ? DateTime.tryParse(v) : null;
