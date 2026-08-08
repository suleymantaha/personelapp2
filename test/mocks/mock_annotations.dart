import 'package:mockito/annotations.dart';
import 'package:personelapp2/core/network/api_client.dart';
import 'package:personelapp2/core/storage/local_storage_service.dart';
import 'package:personelapp2/core/navigation/navigation_service.dart';
import 'package:personelapp2/features/shopping/data/shopping_repository.dart';
import 'package:personelapp2/features/debt/data/debt_repository.dart';
import 'package:personelapp2/features/debt/services/offline_sync_service.dart';

@GenerateNiceMocks([
  MockSpec<ApiClient>(),
  MockSpec<LocalStorageService>(),
  MockSpec<NavigationService>(),
  MockSpec<ShoppingRepository>(),
  MockSpec<DebtRepository>(),
  MockSpec<OfflineSyncService>(),
])
void main() {}
