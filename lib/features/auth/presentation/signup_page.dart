import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // User Fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Company Fields
  final companyNameController = TextEditingController();
  final companyAddressController = TextEditingController();
  final gstNumberController = TextEditingController();
  final companyEmailController = TextEditingController();
  final websiteController = TextEditingController();

  // Logo File
  File? _logoFile;

  Future<void> _pickLogo() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _logoFile = File(pickedFile.path));
    }
  }

  void _signUp() {
    // if (_formKey.currentState?.validate() ?? false) {
    context.go('/subscription');
    final cubit = context.read<AuthCubit>();
    // TODO: Upload _logoFile to Firebase Storage and save URL
    // cubit.signUp(...);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is AuthSuccess) {
            context.go('/subscription');
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "Create Your Company Account",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logo with Edit Icon
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              _logoFile != null ? FileImage(_logoFile!) : null,
                          child:
                              _logoFile == null
                                  ? const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Company Logo",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Info
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator:
                        (value) =>
                            value!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),

                  // Company Info
                  TextFormField(
                    controller: companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Enter company name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: companyAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Company Address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gstNumberController,
                    decoration: const InputDecoration(labelText: 'GST Number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: companyEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Company Email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website (optional)',
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: state is AuthLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child:
                        state is AuthLoading
                            ? const CircularProgressIndicator()
                            : const Text("Sign Up"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
