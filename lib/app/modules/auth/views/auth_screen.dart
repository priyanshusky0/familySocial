import 'package:family_socail/app/modules/auth/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends GetView<AuthController> {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _AppLogo(),
                const SizedBox(height: 20),

                Obx(() => _AuthHeader(isSignUp: controller.isSignUpMode)),
                const SizedBox(height: 20),

                const _AuthForm(),
                const SizedBox(height: 32),

                const _SecureBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FF),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(
        Icons.people_outline,
        size: 45,
        color: Color(0xFF0066FF),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final bool isSignUp;

  const _AuthHeader({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isSignUp ? 'Join Your Family' : 'Welcome Back',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSignUp
              ? 'Create an account to get started'
              : 'Sign in to your family account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _AuthForm extends GetView<AuthController> {
  const _AuthForm();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          Obx(() => _FormTitle(isSignUp: controller.isSignUpMode)),
          const SizedBox(height: 20),

          
          const _InputFields(),
          const SizedBox(height: 20),

         
          const _SubmitButton(),
          const SizedBox(height: 20),

         
          const _OrDivider(),
          const SizedBox(height: 20),

          
          const _SocialLoginButtons(),
          const SizedBox(height: 20),

         
          const _ToggleAuthMode(),
        ],
      ),
    );
  }
}

class _FormTitle extends StatelessWidget {
  final bool isSignUp;

  const _FormTitle({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSignUp ? 'Create Account' : 'Sign In',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isSignUp
              ? 'Enter your details to create your family account'
              : 'Enter your credentials to access your account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _InputFields extends GetView<AuthController> {
  const _InputFields();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          
          if (controller.isSignUpMode) ...[
            AuthTextField(
              controller: controller.nameController,
              label: 'Full Name',
              hint: 'John Doe',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
          ],

          
          AuthTextField(
            controller: controller.emailController,
            label: 'Email',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          
          Obx(() {
            return AuthTextField(
              controller: controller.passwordController,
              label: 'Password',
              hint: controller.isSignUpMode
                  ? 'Create a strong password'
                  : 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: controller.obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            );
          }),

          
          if (controller.isSignUpMode) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Must be at least 8 characters long',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _SubmitButton extends GetView<AuthController> {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: controller.isLoading ? null : controller.handleEmailAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: controller.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  controller.isSignUpMode ? 'Create Account' : 'Sign In',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    });
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or continue with',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialLoginButtons extends GetView<AuthController> {
  const _SocialLoginButtons();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDisabled = controller.isLoading;

      return Row(
        children: [
          Expanded(
            child: SocialLoginButton(
              onPressed: isDisabled ? null : controller.handleGoogleSignIn,
              icon: Image.network(
                "https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png"
                ,
                height: 20,
                width: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata,
                  size: 20,
                ),
              ),
              label: 'Google',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SocialLoginButton(
              onPressed: isDisabled ? null : controller.handleAppleSignIn,
              icon: const Icon(
                Icons.apple,
                size: 24,
                color: Color(0xFF2C3E50),
              ),
              label: 'Apple',
            ),
          ),
        ],
      );
    });
  }
}

class _ToggleAuthMode extends GetView<AuthController> {
  const _ToggleAuthMode();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              controller.isSignUpMode
                  ? "Already have an account? "
                  : "Don't have an account? ",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            GestureDetector(
              onTap: controller.toggleAuthMode,
              child: Text(
                controller.isSignUpMode ? 'Sign In' : 'Sign Up',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 18,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Text(
          'Secure Connection',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}