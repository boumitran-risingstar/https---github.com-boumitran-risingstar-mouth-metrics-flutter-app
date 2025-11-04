import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:mouth_metrics/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  String? _verificationId;
  bool _otpSent = false;
  bool _isVerifying = false;

  Future<void> _sendOtp() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
    });
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+${_phoneNumberController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _syncUserAndNavigate();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
           setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _isVerifying) return;
    setState(() {
      _isVerifying = true;
    });
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      await _auth.signInWithCredential(credential);
      await _syncUserAndNavigate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _syncUserAndNavigate() async {
    try {
      await _userService.syncUser();
      if (mounted) {
        context.go('/home');
      }
    } catch (e, s) {
      developer.log(
        'Error syncing user',
        name: 'mouth_metrics.login',
        error: e,
        stackTrace: s,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Phone Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isVerifying)
              const CircularProgressIndicator()
            else if (!_otpSent) ...[
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number with country code',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendOtp,
                child: const Text('Send OTP'),
              ),
            ] else ...[
              const Text('Enter the OTP sent to your phone'),
              const SizedBox(height: 20),
              Pinput(
                length: 6,
                controller: _otpController,
                onCompleted: (pin) => _verifyOtp(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Verify OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
