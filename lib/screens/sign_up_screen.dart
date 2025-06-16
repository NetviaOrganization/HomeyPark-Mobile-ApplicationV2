import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import the in-app webview package

import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';

// --- Best Practice: Manage the server instance ---
final InAppLocalhostServer _localhostServer = InAppLocalhostServer();

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isRecaptchaVerified = false;
  String? _recaptchaToken;
  bool _isServerRunning = false;

  final RecaptchaV2Controller _recaptchaV2Controller = RecaptchaV2Controller();

  // --- Best Practice: Define constants for paths and URLs ---
  static const String _kRecaptchaHtmlPath = 'assets/recaptcha.html';
  static const String _kRecaptchaURL = 'http://localhost:8080/assets/recaptcha.html';

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  /// Starts the in-app localhost server if it's not already running.
  Future<void> _startServer() async {
    if (!_localhostServer.isRunning()) {
      await _localhostServer.start();
    }
    if (mounted) {
      setState(() {
        _isServerRunning = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isRecaptchaVerified || _recaptchaToken == null) {
      _onRecaptchaError("Por favor completa la verificación reCAPTCHA.");
      return;
    }

    final signUpData = SignUpData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      recaptchaToken: _recaptchaToken!,
    );

    final iamService = Provider.of<IAMService>(context, listen: false);
    final success = await iamService.signUp(signUpData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente! Por favor, inicia sesión.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _onRecaptchaError(String? error) {
    debugPrint('reCAPTCHA Error: $error');
    if (!mounted) return;
    setState(() {
      _isRecaptchaVerified = false;
      _recaptchaToken = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Verification error. Please try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkText,
        title: const Text('Crear Cuenta', style: TextStyle(color: AppColors.darkText)),
        centerTitle: true,
      ),
      body: SafeArea(
        // Show a loading indicator while the server starts, then show the form.
        child: _isServerRunning
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildForm(),
                    const SizedBox(height: 24),
                    AuthLinkText(
                      text: '¿Ya tienes una cuenta? ',
                      linkText: 'Inicia Sesión',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 80),
        const SizedBox(height: 16),
        const Text( 'Únete a la comunidad', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkText), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Crea tu cuenta para comenzar', style: TextStyle(fontSize: 16, color: AppColors.subtleText), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildForm() {
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    final recaptchaSecretKey = dotenv.env['RECAPTCHA_SECRET_KEY'];

    if (recaptchaSiteKey == null || recaptchaSecretKey == null) {
      return const Center(child: Text("reCAPTCHA keys not configured."));
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFormField(
            controller: _nameController,
            labelText: 'Nombre Completo',
            iconData: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value?.trim().length ?? 0) < 2 ? 'El nombre debe tener al menos 2 caracteres' : null,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _emailController,
            labelText: 'Email',
            iconData: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => (value != null && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) ? null : 'Por favor ingresa un email válido',
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _passwordController,
            labelText: 'Contraseña',
            iconData: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            toggleObscureText: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) => (value?.length ?? 0) < 6 ? 'La contraseña debe tener al menos 6 caracteres' : null,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _confirmPasswordController,
            labelText: 'Confirmar Contraseña',
            iconData: Icons.lock_person_outlined,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            toggleObscureText: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) => value != _passwordController.text ? 'Las contraseñas no coinciden' : null,
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 80,
            child: RecaptchaV2(
              apiKey: recaptchaSiteKey,
              apiSecret: recaptchaSecretKey,
              controller: _recaptchaV2Controller,
              // Use the clean, reliable localhost URL.
              pluginURL: _kRecaptchaURL,
              onVerifiedSuccessfully: (isSuccess) {},
              onVerifiedError: (String? data) {
                if (data != null && data.startsWith("err_")) {
                  _onRecaptchaError(data);
                } else {
                  setState(() {
                    _isRecaptchaVerified = true;
                    _recaptchaToken = data;
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          Consumer<IAMService>(
            builder: (context, iamService, child) {
              return Column(
                children: [
                  PrimaryButton(
                    text: 'Crear Cuenta',
                    isLoading: iamService.isLoading,
                    onPressed: _isRecaptchaVerified ? _handleSignUp : null,
                  ),
                  ErrorMessageWidget(errorMessage: iamService.errorMessage),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}