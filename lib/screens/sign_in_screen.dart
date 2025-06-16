import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';

import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';
import 'package:homeypark_mobile_application/screens/sign_up_screen.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isCaptchaVisible = false;

  final RecaptchaV2Controller _recaptchaV2Controller = RecaptchaV2Controller();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isCaptchaVisible = true);
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  Future<void> _signInWithToken(String token) async {
    final signInData = SignInData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      recaptchaToken: token,
    );
    final iamService = Provider.of<IAMService>(context, listen: false);
    await iamService.signIn(signInData);
  }

  // This method will now be used for the onVerifiedError callback
  void _onRecaptchaError(String? error) {
    if (mounted) setState(() => _isCaptchaVisible = false);
    debugPrint('reCAPTCHA Error: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification error. Please try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    final recaptchaSecretKey = dotenv.env['RECAPTCHA_SECRET_KEY'];

    if (recaptchaSiteKey == null || recaptchaSecretKey == null) {
      return const Scaffold(body: Center(child: Text('Error: reCAPTCHA API keys not found.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildForm(),
                  const SizedBox(height: 24),
                  AuthLinkText(text: '¿No tienes una cuenta? ', linkText: 'Regístrate', onTap: _navigateToSignUp),
                ],
              ),
            ),
            Visibility(
              visible: _isCaptchaVisible,
              child: RecaptchaV2(
                apiKey: recaptchaSiteKey,
                apiSecret: recaptchaSecretKey,
                controller: _recaptchaV2Controller,
                pluginURL: "https://www.google.com/recaptcha/api2/demo",

                // --- THE CORRECTED CALLBACK IMPLEMENTATION ---

                // The correct parameter name for the success callback is `onVerified`.
                // It directly provides the verification token as a String.
                 onVerifiedSuccessfully: (bool isSuccess) {
                  // This callback's only job is to hide the captcha view.
                  if (mounted) setState(() => _isCaptchaVisible = false);
                },

                // 2. Use onVerifiedError to GET THE TOKEN or THE ERROR MESSAGE.
                //    This is the primary data callback, despite its confusing name.
                onVerifiedError: (String? data) {
                  // The plugin sends the token on success and an error string on failure
                  // to this same callback.
                  if (data != null && data.startsWith("err_")) {
                    // It's an error.
                    _onRecaptchaError(data);
                  } else {
                    // It's a token!
                    final String token = data ?? "";
                    if (token.isNotEmpty) {
                      _signInWithToken(token);
                    } else {
                       _onRecaptchaError("Verification returned empty data.");
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No changes needed below this line
  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 100),
        const SizedBox(height: 24),
        const Text('Bienvenido de vuelta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkText), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Inicia sesión para continuar en HomeyPark', style: TextStyle(fontSize: 16, color: AppColors.subtleText), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFormField(controller: _emailController, labelText: 'Email', iconData: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) { if (value == null || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) { return 'Por favor ingresa un email válido'; } return null; }),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _passwordController, labelText: 'Contraseña', iconData: Icons.lock_outline, isPassword: true, obscureText: _obscurePassword, toggleObscureText: () => setState(() => _obscurePassword = !_obscurePassword), validator: (value) { if (value == null || value.isEmpty) { return 'Por favor ingresa tu contraseña'; } return null; }),
          const SizedBox(height: 24),
          Consumer<IAMService>(builder: (context, iamService, child) {
            return Column(
              children: [
                PrimaryButton(text: 'Iniciar Sesión', isLoading: iamService.isLoading, onPressed: _handleSignIn),
                ErrorMessageWidget(errorMessage: iamService.errorMessage),
              ],
            );
          }),
        ],
      ),
    );
  }
}