/// Manages the app session state for screen-lock detection.
///
/// Receives native events ("screen_locked" / "screen_unlocked") from Android's
/// BroadcastReceiver (ACTION_SCREEN_OFF / ACTION_USER_PRESENT) via an
/// EventChannel. Only locks the app when the device screen was actually locked.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  bool _sessionActive = false;

  // Set to true when we receive a real "screen_locked" native event.
  // Reset to false after we act on it (i.e. show lock screen).
  bool _screenWasLocked = false;

  /// Call this when the user successfully logs in.
  void startSession() {
    _sessionActive = true;
    _screenWasLocked = false;
  }

  /// Call this when the native side reports the screen turned OFF.
  void onScreenLocked() {
    if (_sessionActive) {
      _screenWasLocked = true;
    }
  }

  /// Call this when the native side reports the user dismissed the lock screen.
  /// Returns [true] if the app should navigate to the Lock Screen.
  bool onScreenUnlocked() {
    if (_sessionActive && _screenWasLocked) {
      clearSession();
      return true; // real screen lock → force login
    }
    return false;
  }

  /// Call this when the app resumes and native channel is unavailable
  /// (e.g. web / desktop fallback). Uses the flag only.
  bool onResumedFallback() {
    if (_sessionActive && _screenWasLocked) {
      clearSession();
      return true;
    }
    return false;
  }

  /// Clears the active session (called on logout or session expiry).
  void clearSession() {
    _sessionActive = false;
    _screenWasLocked = false;
  }

  bool get isSessionActive => _sessionActive;
}

