abstract class NavigationService {
  void navigateTo(String routeName, {Object? arguments});
  void goBack();
  String? get currentRoute;
}

class AppNavigationService implements NavigationService {
  String? _currentRoute = '/';

  @override
  String? get currentRoute => _currentRoute;

  @override
  void navigateTo(String routeName, {Object? arguments}) {
    _currentRoute = routeName;
  }

  @override
  void goBack() {
    _currentRoute = '/';
  }
}
