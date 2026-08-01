import 'package:personelapp2/core/database/database.dart';

class MobileMatrixListEntry {
  const MobileMatrixListEntry.header(this.teamName, this.memberCount)
      : person = null;

  const MobileMatrixListEntry.person(this.person)
      : teamName = null,
        memberCount = null;

  final String? teamName;
  final int? memberCount;
  final PersonelTableData? person;

  bool get isHeader => person == null;
}
