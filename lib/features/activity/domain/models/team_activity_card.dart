class TeamActivityCardResult<T> {
  const TeamActivityCardResult.success(this.value)
      : error = null,
        isSuccess = true;

  const TeamActivityCardResult.failure(this.error)
      : value = null,
        isSuccess = false;

  final T? value;
  final String? error;
  final bool isSuccess;
}

class TeamActivityCard {
  const TeamActivityCard._({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.date,
    required this.activityType,
    required this.assignments,
  });

  final String id;
  final int teamId;
  final String teamName;
  final String date;
  final String activityType;
  final List<dynamic> assignments;

  static TeamActivityCardResult<TeamActivityCard> create({
    required int? teamId,
    required String teamName,
    required String date,
    required String activityType,
    required List<dynamic> assignments,
  }) {
    if (teamId == null || teamName.trim().isEmpty) {
      return const TeamActivityCardResult.failure(
        'Tim kimliği ve adı zorunludur',
      );
    }
    return TeamActivityCardResult.success(
      TeamActivityCard._(
        id: '${date}_$teamId',
        teamId: teamId,
        teamName: teamName.trim(),
        date: date,
        activityType: activityType,
        assignments: assignments,
      ),
    );
  }
}
