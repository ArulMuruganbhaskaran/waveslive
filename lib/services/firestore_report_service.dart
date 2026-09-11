import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../core/constants/app_constants.dart';

const _uuid = Uuid();

/// Firestore + Firebase Storage service for reports.
/// Drop-in replacement for MockDataAcquisitionService + MockReportManagementService.
class FirestoreReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // ── Data Acquisition ─────────────────────────────────────────────────────

  Future<List<ReportModel>> getReportsForAgent(String agentId) async {
    final snap = await _reports
        .where('agentId', isEqualTo: agentId)
        .orderBy('submittedAt', descending: true)
        .get();
    return snap.docs.map((d) => ReportModel.fromFirestore(d)).toList();
  }

  Future<ReportModel?> getReportById(String reportId) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists) return null;
    return ReportModel.fromFirestore(doc);
  }

  /// Upload image to Firebase Storage via [XFile], then create the report doc.
  Future<ReportModel> submitReport({
    required String agentId,
    required String agentName,
    required XFile imageFile,
    required double latitude,
    required double longitude,
    String? locationName,
    String? description,
  }) async {
    final reportId = _uuid.v4();
    final imageUrl = await _uploadImageXFile(imageFile, reportId);
    return _writeReportDoc(
      reportId: reportId,
      agentId: agentId,
      agentName: agentName,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      description: description,
    );
  }

  /// Accept a local file path string (used by provider layer via CaptureState).
  Future<ReportModel> submitReportFromPath({
    required String agentId,
    required String agentName,
    required String imagePath,
    required double latitude,
    required double longitude,
    String? locationName,
    String? description,
  }) async {
    final reportId = _uuid.v4();
    String imageUrl = imagePath;

    if (!kIsWeb) {
      try {
        final ref = _storage.ref('reports/$reportId/image.jpg');
        final snapshot = await ref.putFile(File(imagePath));
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (_) {
        // Fallback: keep local path in dev/emulator
      }
    }

    return _writeReportDoc(
      reportId: reportId,
      agentId: agentId,
      agentName: agentName,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      description: description,
    );
  }

  Future<ReportModel> _writeReportDoc({
    required String reportId,
    required String agentId,
    required String agentName,
    required String imageUrl,
    required double latitude,
    required double longitude,
    String? locationName,
    String? description,
  }) async {
    final now = DateTime.now();
    final report = ReportModel(
      id: reportId,
      agentId: agentId,
      agentName: agentName,
      imagePath: imageUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      capturedAt: now,
      description: description,
      processingStatus: ProcessingStatus.processing,
      verificationStatus: VerificationStatus.pending,
      incidentStatus: IncidentStatus.pending,
      submittedAt: now,
    );

    await _reports.doc(reportId).set(report.toFirestore());
    return report;
  }

  Future<ReportModel> updateReportWithProcessingResult({
    required String reportId,
    required ProcessingResultModel result,
  }) async {
    await _reports.doc(reportId).update({
      'processingStatus': ProcessingStatus.completed,
      'processingResult': result.toMap(),
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
    final doc = await _reports.doc(reportId).get();
    return ReportModel.fromFirestore(doc);
  }

  // ── Report Management ─────────────────────────────────────────────────────

  Future<List<ReportModel>> getAllReports({
    String? hazardTypeFilter,
    String? severityFilter,
    String? verificationStatusFilter,
    String? incidentStatusFilter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query =
        _reports.orderBy('submittedAt', descending: true);

    if (verificationStatusFilter != null &&
        verificationStatusFilter.isNotEmpty) {
      query = query.where('verificationStatus',
          isEqualTo: verificationStatusFilter);
    }
    if (incidentStatusFilter != null && incidentStatusFilter.isNotEmpty) {
      query = query.where('incidentStatus', isEqualTo: incidentStatusFilter);
    }

    final snap = await query.get();
    var reports = snap.docs.map((d) => ReportModel.fromFirestore(d)).toList();

    // Client-side filters for fields Firestore can't compound-query
    if (hazardTypeFilter != null && hazardTypeFilter.isNotEmpty) {
      reports = reports
          .where((r) => r.processingResult?.hazardType == hazardTypeFilter)
          .toList();
    }
    if (severityFilter != null && severityFilter.isNotEmpty) {
      reports = reports
          .where((r) => r.processingResult?.severity == severityFilter)
          .toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      reports = reports
          .where((r) =>
              r.locationName?.toLowerCase().contains(q) == true ||
              r.agentName.toLowerCase().contains(q) ||
              r.processingResult?.hazardType.toLowerCase().contains(q) ==
                  true ||
              r.displayId.toLowerCase().contains(q))
          .toList();
    }

    return reports;
  }

  // ── Verification ──────────────────────────────────────────────────────────

  Future<ReportModel> submitVerification({
    required String reportId,
    required VerificationEntryModel entry,
  }) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists) throw Exception('Report not found');
    final report = ReportModel.fromFirestore(doc);

    final updatedVerifications = [...report.verifications, entry];
    final overallStatus = _computeVerificationStatus(updatedVerifications);

    await _reports.doc(reportId).update({
      'verifications': updatedVerifications.map((v) => v.toMap()).toList(),
      'verificationStatus': overallStatus,
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });

    final updated = await _reports.doc(reportId).get();
    return ReportModel.fromFirestore(updated);
  }

  Future<List<ReportModel>> getPendingVerifications() async {
    final snap = await _reports
        .where('processingStatus', isEqualTo: ProcessingStatus.completed)
        .where('verificationStatus', isEqualTo: VerificationStatus.pending)
        .orderBy('submittedAt', descending: true)
        .get();
    return snap.docs
        .where((d) =>
            (d.data()['processingResult']?['hazardDetected'] as bool?) == true)
        .map((d) => ReportModel.fromFirestore(d))
        .toList();
  }

  Future<List<ReportModel>> getVerifiedReports(String verifierId) async {
    final snap =
        await _reports.orderBy('submittedAt', descending: true).get();
    return snap.docs
        .map((d) => ReportModel.fromFirestore(d))
        .where((r) => r.verifications.any((v) => v.verifierId == verifierId))
        .toList();
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<ReportModel>> watchReportsForAgent(String agentId) {
    return _reports
        .where('agentId', isEqualTo: agentId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReportModel.fromFirestore(d)).toList());
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _uploadImageXFile(XFile imageFile, String reportId) async {
    final ref = _storage.ref('reports/$reportId/image.jpg');
    UploadTask task;
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      task = ref.putFile(File(imageFile.path));
    }
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  String _computeVerificationStatus(List<VerificationEntryModel> vs) {
    if (vs.isEmpty) return VerificationStatus.pending;
    final genuine =
        vs.where((v) => v.result == VerificationResult.genuine).length;
    final falsified =
        vs.where((v) => v.result == VerificationResult.falsified).length;
    final suspicious =
        vs.where((v) => v.result == VerificationResult.suspicious).length;

    if (genuine > falsified && genuine > suspicious) {
      return VerificationStatus.verified;
    } else if (falsified >= genuine) {
      return VerificationStatus.rejected;
    } else {
      return VerificationStatus.suspicious;
    }
  }
}
