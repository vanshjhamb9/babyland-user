import 'dart:async'; // Import for StreamController
import 'dart:developer';

import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Assuming this exists and has an isTokenExpired function
import '../constants/app_constants.dart';

// Define AuthStatus enum
enum AuthStatus {
  authenticated,
  unauthenticated,
  checking,
}

/// Centralized authentication service.
/// Manages token lifecycle, secure storage, and session management.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Initialize the stream controller
    _authStateController = StreamController<AuthStatus>();
    // Optionally, call checkAuthState() here if you want to check on service creation
    // checkAuthState();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _cachedToken;
  String? _cachedUserId;
  String? _cachedRefreshToken;
  bool _isAuthenticated = false; // This will be derived from _cachedToken

  // Declare the stream controller
  late StreamController<AuthStatus> _authStateController;

  // Expose the stream
  Stream<AuthStatus> get authStateChanges => _authStateController.stream;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _cachedUserId;
  String? get token => _cachedToken; // Added getter for token

  // ─── Token Management ───────────────────────────────────

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: AppConstants.keyAuthToken);
    // Update isAuthenticated based on the fetched token
    _isAuthenticated = _cachedToken != null && _cachedToken!.isNotEmpty;
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _isAuthenticated = true;
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
    _authStateController.add(AuthStatus.authenticated); // Emit authenticated status
    notifyListeners();
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    _cachedRefreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
    return _cachedRefreshToken;
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    _cachedRefreshToken = refreshToken;
    await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
    // No need to notifyListeners here unless it changes auth state directly
  }

  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(key: AppConstants.keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    _cachedUserId = await _storage.read(key: AppConstants.keyUserId);
    return _cachedUserId;
  }

  Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: AppConstants.keySessionId, value: sessionId);
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: AppConstants.keySessionId);
  }

  Future<void> saveConversationId(String id) async {
    await _storage.write(key: AppConstants.keyConversationId, value: id);
  }

  Future<String?> getConversationId() async {
    return await _storage.read(key: AppConstants.keyConversationId);
  }

  Future<void> saveTrackerId(String id) async {
    await _storage.write(key: AppConstants.keyTrackerId, value: id);
  }

  Future<String?> getTrackerId() async {
    return await _storage.read(key: AppConstants.keyTrackerId);
  }

  // ─── Authentication State ───────────────────────────────

  /// Checks the authentication status by reading from secure storage.
  /// Migrates legacy keys if found.
  Future<void> checkAuthState() async {
    _authStateController.add(AuthStatus.checking); // Indicate checking state
    try {
      var token = await _storage.read(key: AppConstants.keyAuthToken);
      var userId = await _storage.read(key: AppConstants.keyUserId);
      var refreshToken = await getRefreshToken(); // Also get refresh token for completeness

      // --- Migration from legacy keys (if necessary) ---
      if (token == null || token.isEmpty) {
        final legacyToken = await _storage.read(key: 'token'); // Legacy key
        if (legacyToken != null && legacyToken.isNotEmpty) {
          await _storage.write(key: AppConstants.keyAuthToken, value: legacyToken);
          token = legacyToken;
        }
      }
      // userId legacy key is the same as new key if it exists, so no migration needed for it here.

      // --- Update internal state ---
      _cachedToken = token;
      _cachedUserId = userId;
      _cachedRefreshToken = refreshToken; // Ensure refresh token is also cached

      // --- Determine authentication status ---
      if (token != null && token.isNotEmpty) {
        // Optionally, check token expiration here if you want to proactively log out expired tokens.
        // However, the error logs suggest a refresh-on-401 flow is intended.
        // For now, we will just check if the token exists.
        _isAuthenticated = true;
        _authStateController.add(AuthStatus.authenticated);
      } else {
        _isAuthenticated = false;
        _authStateController.add(AuthStatus.unauthenticated);
      }
    } catch (e) {
      // This handles potential javax.crypto.BadPaddingException (BAD_DECRYPT)
      // which can happen when encryption keys are out of sync.
      pt('Auth check failed due to storage error: $e. Clearing storage.', name: 'AuthService');
      try {
        await _storage.deleteAll();
      } catch (inner) {
        pt('Failed to clear storage: $inner', name: 'AuthService');
      }
      _cachedToken = null;
      _cachedUserId = null;
      _cachedRefreshToken = null;
      _isAuthenticated = false;
      _authStateController.add(AuthStatus.unauthenticated);
    } finally {
      // Ensure notifyListeners is called after state changes
      notifyListeners();
    }
  }

  /// Called when a 401 response is received, indicating the token is expired.
  /// This method should trigger a refresh token flow or log the user out.
  Future<void> onTokenExpired() async {
    if (kDebugMode) log('Token expired — session invalidated', name: 'AuthService');

    final refreshToken = await getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      // TODO: Implement token refresh logic here.
      // This would involve calling a refresh token API endpoint.
      // If refresh is successful, update token and notify listeners.
      // If refresh fails, proceed to logout.
      pt('Refresh token available. Implementing token refresh flow...', name: 'AuthService');
      // For now, simulate logout if refresh token is present but not handled:
      // await logout(); // This is a fallback, ideally refresh happens.
      _isAuthenticated = false;
      _cachedToken = null;
      _cachedRefreshToken = null; // Clear refresh token as well after attempting refresh
      _authStateController.add(AuthStatus.unauthenticated);
      notifyListeners();
    } else {
      // No refresh token, so log out completely.
      await logout();
    }
  }


  /// Logs the user out by clearing tokens and user data from storage.
  Future<void> logout() async {
    // Clear cached values
    _cachedToken = null;
    _cachedUserId = null;
    _cachedRefreshToken = null;
    _isAuthenticated = false;

    // Clear storage
    await _storage.delete(key: AppConstants.keyAuthToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keySessionId);
    await _storage.delete(key: AppConstants.keyConversationId);
    await _storage.delete(key: AppConstants.keyTrackerId);
    await _storage.delete(key: AppConstants.keyFcmToken);

    // Also clear legacy keys if they exist and haven't been migrated properly
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_id'); // Although same key, good to be safe

    // Emit unauthenticated status
    _authStateController.add(AuthStatus.unauthenticated);
    notifyListeners();
  }

  // Ensure the stream controller is closed when the service is no longer needed
  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
