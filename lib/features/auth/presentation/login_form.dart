import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:buildsync/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() {
    final cubit = context.read<AuthCubit>();
    cubit.signIn(emailController.text.trim(), passwordController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is AuthSuccess) {
          context.go('/home'); // requires context from GoRouter
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              // ElevatedButton(
              //   onPressed: state is AuthLoading ? null : _login,
              //   child:
              //       state is AuthLoading
              //           ? const CircularProgressIndicator()
              //           : const Text('Login'),
              // ),
              CustomButton(
                onPressed: state is AuthLoading ? null : _login,
                text: "Login",
              ),
            ],
          ),
        );
      },
    );
  }
}
