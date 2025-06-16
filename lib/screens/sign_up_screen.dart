import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
// 1. Importa el paquete correcto de reCAPTCHA
import 'package:flutter_easy_recaptcha_v2/flutter_easy_recaptcha_v2.dart';

import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 2. Este método ahora coordina la validación y la llamada al reCAPTCHA
  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _showRecaptchaBottomSheet();
  }

  // 3. Lógica para mostrar el Modal Bottom Sheet, idéntica a la de SignInScreen
  void _showRecaptchaBottomSheet() {
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    if (recaptchaSiteKey == null) {
      _onRecaptchaError("La clave del sitio reCAPTCHA no está configurada.");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: RecaptchaV2(
                  apiKey: recaptchaSiteKey,
                  // El único callback necesario, se activa al tener éxito
                  onVerifiedSuccessfully: (String token) {
                    Navigator.pop(context); // Cierra el bottom sheet
                    // La única diferencia es que llamamos al método de registro
                    _signUpWithToken(token); 
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método que se llama con el token después de una verificación exitosa
  Future<void> _signUpWithToken(String token) async {
    final signUpData = SignUpData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      recaptchaToken: token,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkText,
        title: const Text('Crear Cuenta', style: TextStyle(color: AppColors.darkText)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 80),
        const SizedBox(height: 16),
        const Text('Únete a la comunidad', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkText), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Crea tu cuenta para comenzar', style: TextStyle(fontSize: 16, color: AppColors.subtleText), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFormField(controller: _nameController, labelText: 'Nombre Completo', iconData: Icons.person_outline, textCapitalization: TextCapitalization.words, validator: (value) => (value?.trim().length ?? 0) < 3 ? 'El nombre debe tener al menos 3 caracteres' : null),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _emailController, labelText: 'Email', iconData: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) => (value != null && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) ? null : 'Por favor ingresa un email válido'),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _passwordController,
            labelText: 'Contraseña',
            iconData: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            toggleObscureText: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una contraseña';
              }
              // Verificación de 8 caracteres
              if (value.length < 8) {
                return 'La contraseña debe tener al menos 8 caracteres';
              }
              // Verificación de letra mayúscula
              if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                return 'Debe contener al menos una mayúscula';
              }
              // Verificación de letra minúscula
              if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                return 'Debe contener al menos una minúscula';
              }
              // Verificación de un número
              if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                return 'Debe contener al menos un número';
              }
              // Verificación de un carácter especial
              if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
                return 'Debe contener al menos un carácter especial';
              }
              // Si pasa todas las validaciones
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _confirmPasswordController,
            labelText: 'Confirmar Contraseña',
            iconData: Icons.lock_person_outlined,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            toggleObscureText: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, confirma tu contraseña';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          Consumer<IAMService>(builder: (context, iamService, child) {
            return Column(
              children: [
                PrimaryButton(text: 'Crear Cuenta', isLoading: iamService.isLoading, onPressed: _handleSignUp),
                ErrorMessageWidget(errorMessage: iamService.errorMessage),
              ],
            );
          }),
        ],
      ),
    );
  }
}