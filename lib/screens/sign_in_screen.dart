import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
// 1. Importa el paquete correcto de reCAPTCHA
import 'package:flutter_easy_recaptcha_v2/flutter_easy_recaptcha_v2.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. Este método ahora coordina la validación y la llamada al reCAPTCHA
  Future<void> _handleSignIn() async {
    // Oculta el teclado para una mejor experiencia de usuario
    FocusScope.of(context).unfocus();
    // Valida el formulario antes de continuar
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    // Muestra el reCAPTCHA usando el método del bottom sheet
    _showRecaptchaBottomSheet();
  }
  
  // 3. Lógica para mostrar el Modal Bottom Sheet con el reCAPTCHA
  void _showRecaptchaBottomSheet() {
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    if (recaptchaSiteKey == null) {
      _onRecaptchaError("La clave del sitio reCAPTCHA no está configurada.");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el sheet ocupe más espacio vertical
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          // Ocupa el 80% de la altura de la pantalla para dar espacio suficiente
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Botón para cerrar manualmente el modal
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // El widget de reCAPTCHA ocupa el espacio restante
              Expanded(
                child: RecaptchaV2(
                  apiKey: recaptchaSiteKey,
                  // El único callback necesario, se activa al tener éxito
                  onVerifiedSuccessfully: (String token) {
                    Navigator.pop(context); // Cierra el bottom sheet
                    _signInWithToken(token); // Procesa el token obtenido
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSignUp() {
    Provider.of<IAMService>(context, listen: false).clearErrorMessage();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  // Método que se llama con el token después de una verificación exitosa
  Future<void> _signInWithToken(String token) async {
    final signInData = SignInData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      recaptchaToken: token,
    );
    final iamService = Provider.of<IAMService>(context, listen: false);
    await iamService.signIn(signInData);
  }

  // Método genérico para manejar errores de reCAPTCHA
  void _onRecaptchaError(String? error) {
    debugPrint('reCAPTCHA Error: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Error de verificación. Por favor, intenta de nuevo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildForm(),
              const SizedBox(height: 24),
              AuthLinkText(
                text: '¿No tienes una cuenta? ',
                linkText: 'Regístrate',
                onTap: _navigateToSignUp,
              ),
            ],
          ),
        ),
      ),
    );
  }

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