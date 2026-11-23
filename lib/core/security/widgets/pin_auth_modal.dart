import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../services/pin_auth_service.dart';

class PinAuthModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool allowBiometrics;

  const PinAuthModal({
    super.key,
    this.title = 'Confirmation du code PIN',
    this.subtitle = 'Saisissez votre code pour continuer',
    this.allowBiometrics = true,
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Confirmation du code PIN',
    String subtitle = 'Saisissez votre code pour continuer',
    bool allowBiometrics = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (_) => PinAuthModal(
        title: title,
        subtitle: subtitle,
        allowBiometrics: allowBiometrics,
      ),
    );

    return result ?? false;
  }

  @override
  State<PinAuthModal> createState() => _PinAuthModalState();
}

class _PinAuthModalState extends State<PinAuthModal> {
  static const Color _primary = Color(0xFF173D32);
  static const Color _gold = Color(0xFFD9B868);
  static const Color _danger = Color(0xFFB42318);

  final LocalAuthentication _localAuth = LocalAuthentication();

  String _pin = '';
  String _message = '';
  bool _isChecking = false;
  bool _biometricAvailable = false;
  bool _isBiometricLoading = false;
  bool _isShaking = false;

  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _refreshLockMessage();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    if (!widget.allowBiometrics) return;

    try {
      final available = await _localAuth.getAvailableBiometrics();

      if (!mounted) return;

      setState(() {
        _biometricAvailable = available.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  void _refreshLockMessage() {
    if (!PinAuthService.isLocked) return;

    _lockTimer?.cancel();

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!PinAuthService.isLocked) {
        timer.cancel();

        setState(() {
          _message = '';
        });

        return;
      }

      setState(() {
        _message =
            'Trop d’essais. Réessayez dans '
            '${PinAuthService.remainingLockSeconds} s.';
      });
    });

    setState(() {
      _message =
          'Trop d’essais. Réessayez dans '
          '${PinAuthService.remainingLockSeconds} s.';
    });
  }

  void _pressKey(String key) {
    if (_isChecking || _isBiometricLoading) return;

    if (PinAuthService.isLocked) {
      _refreshLockMessage();
      return;
    }

    HapticFeedback.selectionClick();

    if (key == 'del') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _message = '';
        });
      }
      return;
    }

    if (_pin.length >= 4) return;

    setState(() {
      _pin += key;
      _message = '';
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 140));

    try {
      final configured = await PinAuthService.hasPin();

      if (!mounted) return;

      // if (!configured) {
      //   setState(() {
      //     _pin = '';
      //     _isChecking = false;
      //     _message = 'Aucun code PIN n’est encore configuré.';
      //   });
      //   return;
      // }

      // final isValid = await PinAuthService.verifyPin(_pin);

      // if (!mounted) return;

      //  if (isValid) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      // return;
      //  }

      setState(() {
        _pin = '';
        _isChecking = false;
        _isShaking = true;
      });

      // HapticFeedback.heavyImpact();

      // if (PinAuthService.isLocked) {
      //   _refreshLockMessage();
      // } else {
      //   final remaining = PinAuthService.remainingAttempts;

      //   setState(() {
      //     _message =
      //         'Code incorrect. Il vous reste $remaining '
      //         'essai${remaining > 1 ? 's' : ''}.';
      //   });
      // }

      await Future<void>.delayed(const Duration(milliseconds: 450));

      if (mounted) {
        setState(() {
          _isShaking = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _pin = '';
        _isChecking = false;
        _message = 'Une erreur est survenue. Réessayez.';
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isBiometricLoading || _isChecking) return;

    setState(() {
      _isBiometricLoading = true;
      _message = '';
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirmez votre identité pour continuer',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!mounted) return;

      if (authenticated) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _message = 'Authentification biométrique non validée.';
        _isBiometricLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = 'Biométrie indisponible. Utilisez votre code PIN.';
        _isBiometricLoading = false;
      });
    }
  }

  Widget _buildDot(int index) {
    final active = index < _pin.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _primary : Colors.transparent,
        border: Border.all(
          color: active ? _primary : const Color(0xFF9BA69F),
          width: 1.8,
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    final isDelete = value == 'del';

    return Material(
      color: const Color(0xFFF1F3F1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isChecking || _isBiometricLoading
            ? null
            : () => _pressKey(value),
        child: SizedBox(
          height: 56,
          child: Center(
            child: isDelete
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 23,
                    color: _primary,
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF202923),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'bio',
      '0',
      'del',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 56,
        crossAxisSpacing: 14,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];

        if (key == 'bio') {
          if (!_biometricAvailable) {
            return const SizedBox.shrink();
          }

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _authenticateWithBiometrics,
              child: const Center(
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: _primary,
                  size: 30,
                ),
              ),
            ),
          );
        }

        return _buildKey(key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DED9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17231C),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF65716A),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF77827B),
                  ),
                ),

                const SizedBox(height: 22),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(
                    _isShaking ? -7 : 0,
                    0,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: _buildDot(index),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 20,
                  child: Center(
                    child: Text(
                      _isChecking || _isBiometricLoading
                          ? 'Vérification en cours...'
                          : _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                _buildKeypad(),

                const SizedBox(height: 12),

                if (_biometricAvailable)
                  Text(
                    'Utilisez votre empreinte ou votre code PIN',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
