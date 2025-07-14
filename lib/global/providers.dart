import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/data/firebase_auth_data_source.dart';
import '../features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

final globalProviders = [
  BlocProvider<AuthCubit>(
    create:
        (context) => AuthCubit(
          AuthRepository(
            FirebaseAuthDataSource(
              FirebaseAuth.instance,
              FirebaseFirestore.instance,
            ),
          ),
        ),
  ),
];
