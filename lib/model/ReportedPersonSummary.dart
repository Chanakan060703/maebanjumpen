import 'package:maebanjumpen/model/person.dart';
import 'package:maebanjumpen/model/report.dart';

class ReportedPersonSummary {
  final Person reportedPerson;
  final String userTypeForDisplay;
  final int totalReportCount;
  final Report latestReport;
  final List<Report> allReports;

  ReportedPersonSummary({
    required this.reportedPerson,
    required this.userTypeForDisplay,
    required this.totalReportCount,
    required this.latestReport,
    required this.allReports,
  });
}
