/// Enums shared across multiple endpoints.
library;

enum DocumentType {
  trIdCard,
  passport,
  driverLicense,
  euNationalId,
  ukPassport,
}

extension DocumentTypeWire on DocumentType {
  String get wire => switch (this) {
        DocumentType.trIdCard => 'tr_id_card',
        DocumentType.passport => 'passport',
        DocumentType.driverLicense => 'driver_license',
        DocumentType.euNationalId => 'eu_national_id',
        DocumentType.ukPassport => 'uk_passport',
      };
  static DocumentType from(String s) => switch (s) {
        'tr_id_card' => DocumentType.trIdCard,
        'passport' => DocumentType.passport,
        'driver_license' => DocumentType.driverLicense,
        'eu_national_id' => DocumentType.euNationalId,
        'uk_passport' => DocumentType.ukPassport,
        _ => DocumentType.passport,
      };
}

enum DocumentSide { front, back, single }

extension DocumentSideWire on DocumentSide {
  String get wire => name;
}

enum Intent { onboarding, reVerification, periodicReview }

extension IntentWire on Intent {
  String get wire => switch (this) {
        Intent.onboarding => 'onboarding',
        Intent.reVerification => 're_verification',
        Intent.periodicReview => 'periodic_review',
      };
}

enum Sex { male, female }

extension SexWire on Sex {
  String get wire => this == Sex.male ? 'M' : 'F';
}

/// UI buckets returned by the status endpoint. Route your screens
/// off this, never off the internal state name.
enum KycCurrentStep {
  readyToUploadDocument,
  uploadDocument,
  processingDocument,
  uploadNfc,
  uploadSelfie,
  processingBiometrics,
  deciding,
  completedApproved,
  completedRejected,
  inManualReview,
  retryPending,
  expired,
  canceled,
  unknown,
}

extension KycCurrentStepWire on KycCurrentStep {
  static KycCurrentStep from(String? s) => switch (s) {
        'ready_to_upload_document' => KycCurrentStep.readyToUploadDocument,
        'upload_document' => KycCurrentStep.uploadDocument,
        'processing_document' => KycCurrentStep.processingDocument,
        'upload_nfc' => KycCurrentStep.uploadNfc,
        'upload_selfie' => KycCurrentStep.uploadSelfie,
        'processing_biometrics' => KycCurrentStep.processingBiometrics,
        'deciding' => KycCurrentStep.deciding,
        'completed_approved' => KycCurrentStep.completedApproved,
        'completed_rejected' => KycCurrentStep.completedRejected,
        'in_manual_review' => KycCurrentStep.inManualReview,
        'retry_pending' => KycCurrentStep.retryPending,
        'expired' => KycCurrentStep.expired,
        'canceled' => KycCurrentStep.canceled,
        _ => KycCurrentStep.unknown,
      };

  bool get isTerminal => this == KycCurrentStep.completedApproved ||
      this == KycCurrentStep.completedRejected ||
      this == KycCurrentStep.expired ||
      this == KycCurrentStep.canceled;
}

enum DecisionOutcome { approved, rejected, manualReview }

extension DecisionOutcomeWire on DecisionOutcome {
  String get wire => switch (this) {
        DecisionOutcome.approved => 'approved',
        DecisionOutcome.rejected => 'rejected',
        DecisionOutcome.manualReview => 'manual_review',
      };
  static DecisionOutcome? from(String? s) => switch (s) {
        'approved' => DecisionOutcome.approved,
        'rejected' => DecisionOutcome.rejected,
        'manual_review' => DecisionOutcome.manualReview,
        _ => null,
      };
}
