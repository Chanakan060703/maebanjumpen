// lib/model/report.dart
import 'package:flutter/material.dart';
// สามารถลบได้หากไม่ใช้ class Hirer ตรงๆ ในไฟล์นี้
// สามารถลบได้หากไม่ใช้ class Housekeeper ตรงๆ ในไฟล์นี้
import 'package:maebanjumpen/model/party_role.dart';
import 'package:maebanjumpen/model/penalty.dart';
// สามารถลบได้หากไม่ใช้ function จาก dart:convert ตรงๆ ในไฟล์นี้

class Report {
  final int? reportId;
  final String? reportTitle;
  final String? reportMessage;
  final DateTime? reportDate;
  final String? reportStatus;
  final PartyRole? reporter;
  final PartyRole? hirer; // เปลี่ยนเป็น PartyRole? ตามที่ต้องการ
  final PartyRole? housekeeper; // เปลี่ยนเป็น PartyRole? ตามที่ต้องการ
  final Penalty? penalty;
  final int? reportCount;

  Report({
    this.reportId,
    this.reportTitle,
    this.reportMessage,
    this.reportDate,
    this.reportStatus,
    this.reporter,
    this.hirer,
    this.housekeeper,
    this.penalty,
    this.reportCount,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] as int?,
      reportTitle: json['reportTitle'] as String?,
      reportMessage: json['reportMessage'] as String?,
      reportDate: json['reportDate'] != null
          ? DateTime.parse(json['reportDate'])
          : null,
      reportStatus: json['reportStatus'] as String?,
      reporter: json['reporter'] != null
          ? PartyRole.fromJson(json['reporter'] as Map<String, dynamic>)
          : null,
      hirer: json['hirer'] != null
          ? PartyRole.fromJson(json['hirer'] as Map<String, dynamic>)
          : null,
      housekeeper: json['housekeeper'] != null
          ? PartyRole.fromJson(json['housekeeper'] as Map<String, dynamic>)
          : null,
      penalty: json['penalty'] != null
          ? Penalty.fromJson(json['penalty'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reportId'] = reportId;
    data['reportTitle'] = reportTitle;
    data['reportMessage'] = reportMessage;
    data['reportDate'] = reportDate?.toIso8601String();
    data['reportStatus'] = reportStatus;

    if (reporter != null && reporter!.id != null && reporter!.type != null) {
      data['reporter'] = {
        'id': reporter!.id,
        'type': reporter!.type,
      };
    } else {
      debugPrint('Warning: Attempting to send Report with null or invalid reporter: $reporter');
      data['reporter'] = null; // ส่ง null กลับไปหากข้อมูลไม่สมบูรณ์
    }

    if (hirer != null && hirer!.id != null && hirer!.type != null) {
      data['hirer'] = {
        'id': hirer!.id,
        'type': hirer!.type,
      };
    } else {
      data['hirer'] = null;
    }

    if (housekeeper != null && housekeeper!.id != null && housekeeper!.type != null) {
      data['housekeeper'] = {
        'id': housekeeper!.id,
        'type': housekeeper!.type,
      };
    } else {
      data['housekeeper'] = null;
    }

    if (penalty != null && penalty!.penaltyId != null) {
      data['penalty'] = {
        'penaltyId': penalty!.penaltyId,
      };
    } else {
      data['penalty'] = null;
    }

    return data;
  }
}