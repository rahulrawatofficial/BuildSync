// import 'package:buildsync/global/blocs/auth_cubit.dart';
// import 'package:buildsync/shared/widgets/custom_button.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';

// class LoginForm extends StatefulWidget {
//   const LoginForm({super.key});

//   @override
//   State<LoginForm> createState() => _LoginFormState();
// }

// class _LoginFormState extends State<LoginForm> {
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   bool _obscurePassword = true;

//   void _login() {
//     final cubit = context.read<AuthCubit>();
//     cubit.signIn(emailController.text.trim(), passwordController.text.trim());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<AuthCubit, AuthState>(
//       listener: (context, state) {
//         if (state is AuthFailure) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(state.message)));
//         }
//         if (state is AuthSuccess) {
//           context.go('/home');
//         }
//       },
//       builder: (context, state) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Title
//             Text(
//               "Welcome Back",
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               "Log in to continue with BuildSync",
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 24),

//             // Email Field
//             TextField(
//               controller: emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: InputDecoration(
//                 labelText: 'Email',
//                 prefixIcon: const Icon(Icons.email_outlined),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Password Field
//             TextField(
//               controller: passwordController,
//               obscureText: _obscurePassword,
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 prefixIcon: const Icon(Icons.lock_outline),
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                   ),
//                   onPressed: () {
//                     setState(() => _obscurePassword = !_obscurePassword);
//                   },
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Login Button
//             CustomButton(
//               onPressed: state is AuthLoading ? null : _login,
//               text: state is AuthLoading ? "Loading..." : "Login",
//             ),
//             const SizedBox(height: 16),

//             // Sign up Button
//             Center(
//               child: TextButton(
//                 onPressed: () {
//                   context.go('/signup'); // Navigate to sign up page
//                 },
//                 child: const Text(
//                   "Don't have an account? Sign Up",
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
