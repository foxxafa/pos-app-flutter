import 'package:flutter/foundation.dart';
import 'package:pos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos_app/features/auth/domain/entities/user_model.dart';

class UserProvider extends ChangeNotifier {
  final AuthRepository? _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  UserProvider({AuthRepository? authRepository}) : _authRepository = authRepository {
    _loadCurrentUser();
  }

  // Getter'lar
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  // Legacy getters for backward compatibility
  String get username => _currentUser?.username ?? '';
  String get password => _currentUser?.password ?? '';
  String get apikey => _currentUser?.apikey ?? '';
  int get day => _currentUser?.day ?? 0;

  /// Login with repository pattern
  Future<bool> login(String username, String password) async {
    if (_authRepository == null) {
      _setError('Auth repository not available');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.login(username, password);

      if (result?.success == true && result?.user != null) {
        _currentUser = result!.user;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        _setError(result?.message ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout with repository pattern
  Future<void> logout() async {
    if (_authRepository == null) return;

    try {
      await _authRepository.logout();
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      _setError('Logout error: ${e.toString()}');
    }
  }

  /// Load current user from repository
  Future<void> _loadCurrentUser() async {
    if (_authRepository == null) return;

    try {
      _isLoggedIn = await _authRepository.isLoggedIn();
      if (_isLoggedIn) {
        _currentUser = await _authRepository.getCurrentUser();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  /// Update repository reference (for DI)
  void updateRepository(AuthRepository repository) {
    // This method can be used to update repository reference if needed
  }

  // Legacy setters for backward compatibility
  void setUser({
    required String username,
    required String password,
    required String apikey,
    required int day,
  }) {
    _currentUser = UserModel(
      username: username,
      password: password,
      apikey: apikey,
      day: day,
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _isLoggedIn = false;
    _clearError();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (!_isLoading) notifyListeners();
  }
}
