import 'package:mockito/annotations.dart';
import 'package:personelapp2/core/network/api_client.dart';
import 'package:personelapp2/core/storage/local_storage_service.dart';
import 'package:personelapp2/core/navigation/navigation_service.dart';

@GenerateNiceMocks([
  MockSpec<ApiClient>(),
  MockSpec<LocalStorageService>(),
  MockSpec<NavigationService>(),
])
void main() {}
