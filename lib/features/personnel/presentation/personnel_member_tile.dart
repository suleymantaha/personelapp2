part of 'personnel_management_screen.dart';

extension _PersonnelMemberTile on _PersonnelManagementScreenState {
  Widget _buildMemberTile(PersonelTableData person, int index, bool isAdmin) =>
      Padding(
          padding:
              const EdgeInsets.only(left: 14, top: 12, right: 4, bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 26,
                child: Text('${index + 1}.',
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12))),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(person.rutbe,
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary)),
                  const SizedBox(height: 3),
                  Text(person.adSoyad,
                      softWrap: true,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ])),
            if (isAdmin) _buildMemberMenu(person),
          ]));
}
