enum DebtStatus { active, paid, overdue }

class InstallmentPlan {
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidDate;

  const InstallmentPlan({
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
  });

  InstallmentPlan copyWith({
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? paidDate,
  }) {
    return InstallmentPlan(
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'installmentNumber': installmentNumber,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'paidDate': paidDate?.toIso8601String(),
      };

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) => InstallmentPlan(
        installmentNumber: json['installmentNumber'] as int,
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
        isPaid: json['isPaid'] as bool? ?? false,
        paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      );
}

class DebtItem {
  final String id;
  final String debtorName;
  final double totalAmount;
  final double remainingAmount;
  final DateTime createdAt;
  final DebtStatus status;
  final List<InstallmentPlan> installments;
  final bool isSynced;

  const DebtItem({
    required this.id,
    required this.debtorName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.createdAt,
    this.status = DebtStatus.active,
    this.installments = const [],
    this.isSynced = true,
  });

  DebtItem copyWith({
    String? id,
    String? debtorName,
    double? totalAmount,
    double? remainingAmount,
    DateTime? createdAt,
    DebtStatus? status,
    List<InstallmentPlan>? installments,
    bool? isSynced,
  }) {
    return DebtItem(
      id: id ?? this.id,
      debtorName: debtorName ?? this.debtorName,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      installments: installments ?? this.installments,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'debtorName': debtorName,
        'totalAmount': totalAmount,
        'remainingAmount': remainingAmount,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'installments': installments.map((e) => e.toJson()).toList(),
        'isSynced': isSynced,
      };

  factory DebtItem.fromJson(Map<String, dynamic> json) => DebtItem(
        id: json['id'] as String,
        debtorName: json['debtorName'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        remainingAmount: (json['remainingAmount'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: DebtStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DebtStatus.active,
        ),
        installments: (json['installments'] as List<dynamic>?)
                ?.map((e) => InstallmentPlan.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        isSynced: json['isSynced'] as bool? ?? true,
      );
}
