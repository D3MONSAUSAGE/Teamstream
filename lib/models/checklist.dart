import 'package:pocketbase/pocketbase.dart';

class Checklist {
  final String id;
  final String title;
  final String branch;
  final String area;
  final String shift;
  final DateTime date;
  final bool executed;
  final bool verified;

  Checklist({
    required this.id,
    required this.title,
    required this.branch,
    required this.area,
    required this.shift,
    required this.date,
    required this.executed,
    required this.verified,
  });

  // Factory constructor to create Checklist from PocketBase RecordModel
  factory Checklist.fromRecord(RecordModel record) {
    return Checklist(
      id: record.id,
      title: record.getStringValue('title'),
      branch: record.getStringValue('branch'),
      area: record.getStringValue('area'),
      shift: record.getStringValue('shift'),
      date: DateTime.parse(record.getStringValue('date')),
      executed: record.getBoolValue('executed'),
      verified: record.getBoolValue('verified'),
    );
  }

  // Convert to JSON for potential updates/creates (optional)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'branch': branch,
      'area': area,
      'shift': shift,
      'date': date.toIso8601String(),
      'executed': executed,
      'verified': verified,
    };
  }
}
