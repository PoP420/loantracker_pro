import 'dart:ui';

class Transaction {
  final int id;
  final int loanId;
  final double principalDue;
  final double interestDue;
  final double penaltiesDue;
  final double totalDue;
  final double weeklyDue;
  final double serviceFeesDue;
  final DateTime dueDate;
  final DateTime monthlyDueDate;
  final bool isPaid;
  final String? remarks;
  final int penaltyMonthsApplied;

  Transaction({
    required this.id,
    required this.loanId,
    this.principalDue = 0.0,
    this.interestDue = 0.0,
    this.penaltiesDue = 0.0,
    required this.totalDue,
    this.weeklyDue = 0.0,
    this.serviceFeesDue = 0.0,
    required this.dueDate,
    required this.monthlyDueDate,
    required this.isPaid,
    this.remarks,
    this.penaltyMonthsApplied = 0,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      loanId: json['loanID'] ?? 0,
      principalDue: (json['principalDue'] ?? 0.0).toDouble(),
      interestDue: (json['interestDue'] ?? 0.0).toDouble(),
      penaltiesDue: (json['penaltiesDue'] ?? 0.0).toDouble(),
      totalDue: (json['totalDue'] ?? 0.0).toDouble(),
      weeklyDue: (json['weeklyDue'] ?? 0.0).toDouble(),
      serviceFeesDue: (json['serviceFeesDue'] ?? 0.0).toDouble(),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      monthlyDueDate: DateTime.tryParse(json['monthlyDueDate']?.toString() ?? '') ?? DateTime.now(),
      isPaid: json['isPaid'] == true,
      remarks: json['remarks'],
      penaltyMonthsApplied: json['penaltyMonthsApplied'] ?? 0,
    );
  }

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
  bool get hasPenalties => penaltiesDue > 0;
  bool get hasServiceFees => serviceFeesDue > 0;

  double get amount => totalDue; // For backward compatibility

  String get statusText {
    if (isPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }

  Color get statusColor {
    if (isPaid) return const Color(0xFF4CAF50); // Green
    if (isOverdue) return const Color(0xFFF44336); // Red
    return const Color(0xFFFF9800); // Orange
  }
}
