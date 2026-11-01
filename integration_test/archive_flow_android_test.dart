import 'package:intl/date_symbol_data_local.dart';
import 'package:integration_test/integration_test.dart';
import '../test/support/archive_flow_scenario.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  var converted = false;
  archiveFlowScenario(onScreen: (name, tester) async {
    if (!converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
    }
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  });
}
