import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/domain/personnel_display_order.dart';

/// Matrix and Excel share the saved management-screen ordering.
List<PersonelTableData> orderMatrixPersonnel(
  Iterable<PersonelTableData> personnel,
  Iterable<TimTableData> squads,
) =>
    orderDisplayPersonnel(personnel, squads);
