class PaymentRequestDto {
  final int loanID;
  final int userID;
  final int loanTransactionID;
  final double amount;
  final DateTime? paymentDate;

  PaymentRequestDto({
    required this.loanID,
    required this.userID,
    required this.loanTransactionID,
    required this.amount,
    this.paymentDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'LoanID': loanID,
      'UserID': userID,
      'LoanTransactionID': loanTransactionID,
      'Amount': amount,
      'PaymentDate': paymentDate?.toIso8601String(),
    };
  }
}
