import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../repositories/settings_repository.dart';
import 'auth_service.dart';
import 'screen_protection.dart';

/// アプリ全体を覆い、
/// ・起動時認証
/// ・バックグラウンド復帰時の再認証（設定に応じて）
/// ・無操作タイムアウトによる自動ロック
/// を一元管理するゲートウィジェット。
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _authInProgress = false;
  Timer? _idleTimer;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenProtectionService.instance.enable();
    _attemptUnlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    final lockOnBackground =
        await SettingsRepository.instance.getBool(AppSettingsKeys.lockOnBackground);
    final autoLockSeconds =
        await SettingsRepository.instance.getInt(AppSettingsKeys.autoLockSeconds);

    final elapsed = _backgroundedAt == null
        ? Duration.zero
        : DateTime.now().difference(_backgroundedAt!);

    final shouldLock = lockOnBackground ||
        (autoLockSeconds > 0 && elapsed.inSeconds >= autoLockSeconds);

    if (shouldLock && _unlocked) {
      setState(() => _unlocked = false);
    }
    if (!_unlocked) {
      _attemptUnlock();
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    SettingsRepository.instance.getInt(AppSettingsKeys.autoLockSeconds).then((seconds) {
      if (seconds <= 0 || !mounted) return;
      _idleTimer = Timer(Duration(seconds: seconds), () {
        if (mounted && _unlocked) {
          setState(() => _unlocked = false);
          _attemptUnlock();
        }
      });
    });
  }

  Future<void> _attemptUnlock() async {
    if (_authInProgress) return;
    _authInProgress = true;
    try {
      final bioAvailable = await AuthService.instance.isBiometricAvailable();
      if (bioAvailable) {
        final ok = await AuthService.instance.authenticateWithBiometrics();
        if (ok && mounted) {
          setState(() => _unlocked = true);
          _resetIdleTimer();
          return;
        }
      }
      // 生体認証が使えない/失敗した場合はPIN画面へ誘導する（build内で表示）。
    } finally {
      _authInProgress = false;
      if (mounted) setState(() {});
    }
  }

  void _onPinUnlocked() {
    setState(() => _unlocked = true);
    _resetIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _LockScreen(
          onUnlocked: _onPinUnlocked,
          onRetryBiometric: _attemptUnlock,
        ),
      );
    }
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class _LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback onRetryBiometric;
  const _LockScreen({required this.onUnlocked, required this.onRetryBiometric});

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _pinConfigured = true;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasPin = await AuthService.instance.hasPinConfigured();
    setState(() {
      _pinConfigured = hasPin;
      _checking = false;
    });
  }

  Future<void> _submitPin() async {
    if (!_pinConfigured) {
      final result = await AuthService.instance.setPin(
        _pinController.text,
        _confirmController.text,
      );
      switch (result) {
        case PinSetResult.tooShort:
          setState(() => _error = 'PINは4桁以上で設定してください');
          return;
        case PinSetResult.mismatch:
          setState(() => _error = 'PINが一致しません');
          return;
        case PinSetResult.ok:
          widget.onUnlocked();
          return;
      }
    }

    final result = await AuthService.instance.verifyPin(_pinController.text);
    switch (result) {
      case PinVerifyResult.ok:
        widget.onUnlocked();
        break;
      case PinVerifyResult.wrong:
        setState(() {
          _error = 'PINが違います';
          _pinController.clear();
        });
        break;
      case PinVerifyResult.lockedOut:
        final remaining = await AuthService.instance.currentLockoutRemaining();
        setState(() {
          _error = '試行回数が上限に達しました。'
              '${remaining?.inMinutes ?? 5}分後に再試行してください';
          _pinController.clear();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64),
                const SizedBox(height: 16),
                Text(
                  _pinConfigured ? 'アプリロック中' : 'アプリ専用PINを設定してください',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                if (!_pinConfigured) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'PIN（確認）'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitPin,
                  child: Text(_pinConfigured ? '解除' : 'PINを設定'),
                ),
                if (_pinConfigured) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: widget.onRetryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('生体認証を再試行'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
