/// eMRTD chip-read interface.
///
/// The full ICAO 9303 BAC + PACE + Active-Authentication protocol is
/// 5-10 kLOC of crypto and APDU framing. Maintaining that against
/// every Flutter / Android / iOS NFC API change is more work than
/// any single SDK should carry.
///
/// **What this module provides:**
///   * [NfcReadResult] — the typed envelope your read implementation
///     returns + that the flow controller posts to the API.
///   * [NfcReader] — abstract interface. Implement it with your chip
///     library of choice (e.g. `dmrtd`, `passport_nfc_reader`,
///     `nfc_manager` + manual APDU).
///   * [SimulatedNfcReader] — drop-in fake for UI development.
///
/// Recommended packages (none of them is a hard dependency here):
///
///   * `nfc_manager` — low-level chip session for both iOS + Android.
///   * `dmrtd` — Dart port of the Java JMRTD library; gives you SOD +
///     Data Group parsing and BAC.
///   * `passport_nfc_reader` (community) — wraps the above with a
///     friendlier API.
///
/// The flow controller takes raw bytes; you can hand it whatever your
/// reader produces.
library;

import 'dart:async';
import 'dart:typed_data';

class NfcReadResult {
  /// `'BAC'` or `'PACE'`.
  final String protocol;

  /// `'MRZ'` or `'CAN'` (only relevant for PACE).
  final String? keyDerivation;

  /// SOD (Security Object Document) — signed envelope over the DG
  /// hashes. Mandatory for any successful chip read.
  final Uint8List sod;

  final Uint8List? dg1; // MRZ
  final Uint8List? dg2; // Face image
  final Uint8List? dg11; // Extended personal details
  final Uint8List? dg14; // Chip Authentication public key
  final Uint8List? dg15; // Active Authentication public key

  /// AA challenge response (when DG15 is present and your library
  /// performed the AA round-trip).
  final Uint8List? activeAuthentication;

  const NfcReadResult({
    required this.protocol,
    this.keyDerivation,
    required this.sod,
    this.dg1,
    this.dg2,
    this.dg11,
    this.dg14,
    this.dg15,
    this.activeAuthentication,
  });
}

/// Abstract reader interface. Provide an implementation per platform
/// using your favourite NFC plugin.
abstract class NfcReader {
  /// Read the chip using the supplied MRZ (date-of-birth + document
  /// number + expiry, in YYMMDD format) for BAC key derivation.
  /// PACE-only chips ignore the MRZ-derived key but still need it for
  /// the PACE password input — supply it regardless.
  Future<NfcReadResult> read({
    required String documentNumber,
    required String dateOfBirthYymmdd,
    required String expiryDateYymmdd,
    Duration timeout = const Duration(seconds: 30),
  });

  /// Cancel any in-flight read.
  Future<void> cancel();
}

/// Drop-in fake that returns canned bytes. Use it while wiring up
/// your UI before integrating a real chip library.
class SimulatedNfcReader implements NfcReader {
  final NfcReadResult fixture;
  final Duration delay;
  SimulatedNfcReader(this.fixture,
      {this.delay = const Duration(seconds: 2)});

  @override
  Future<NfcReadResult> read({
    required String documentNumber,
    required String dateOfBirthYymmdd,
    required String expiryDateYymmdd,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await Future<void>.delayed(delay);
    return fixture;
  }

  @override
  Future<void> cancel() async {}
}
