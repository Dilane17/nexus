import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/widgets/nexus_button.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _timerSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).resendOtp(widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un nouveau code a été envoyé.'),
            backgroundColor: NexusColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verify() async {
    if (_otpController.text.length < 5) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).verifyEmail(
            email: widget.email,
            code: _otpController.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NexusSpacing.containerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vérification', style: NexusTypography.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Entrez le code envoyé à ${widget.email}',
                style: NexusTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                textAlign: TextAlign.center,
                style: NexusTypography.textTheme.displayMedium?.copyWith(
                  letterSpacing: 16,
                  color: NexusColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: '00000',
                  counterText: '',
                  hintStyle: TextStyle(color: NexusColors.outlineVariant),
                ),
                onChanged: (val) {
                  if (val.length == 5) _verify();
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: TextStyle(color: NexusColors.error)),
              ],

              const Spacer(),

              NexusButton(
                label: 'Vérifier le code',
                onPressed: _verify,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _timerSeconds == 0 && !_isLoading ? _resendCode : null,
                  child: Text(
                    _timerSeconds > 0
                        ? 'Renvoyer le code (${_timerSeconds}s)'
                        : 'Renvoyer le code',
                    style: TextStyle(
                      color: _timerSeconds > 0 ? NexusColors.outline : NexusColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
