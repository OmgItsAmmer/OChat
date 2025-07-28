import 'package:dartz/dartz.dart';
import 'package:frontend/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/auth_repo.dart';

class AuthRepoImpl extends AuthRepo {
  
 @override
Future<Either<AuthFailure, void>> login(String email, String password) async {
  try {
        await supabase.auth.signInWithPassword(email: email, password: password);
    return const Right(null);
  } catch (e) {
    if (e is AuthException) {
      return Left(AuthFailure(e.message));
    }
    return Left(AuthFailure(e.toString()));
  }
}

@override
Future<Either<AuthFailure, void>> signup(String email, String password) async {
  try {
    await supabase.auth.signUp(email: email, password: password);
    return const Right(null);
  } catch (e) {
    if (e is AuthException) {
      return Left(AuthFailure(e.message));
    }
    return Left(AuthFailure('Unexpected error: ${e.toString()}'));
  }
}


 @override
Future<Either<AuthFailure, void>> logout() async {
  try {
    await supabase.auth.signOut();
    return const Right(null);
  } catch (e) {
    if (e is AuthException) {
      return Left(AuthFailure(e.message));
    }
    return Left(AuthFailure('Unexpected error: ${e.toString()}'));
  }
}


  @override
    Future<Either<AuthFailure, void>> resetPassword(String email, String password) async {
      try {
        await supabase.auth.resetPasswordForEmail(email, redirectTo: 'your-app://reset-password');
        return const Right(null);
      } catch (e) {
        if (e is AuthException) {
          return Left(AuthFailure(e.message));
        }
        return Left(AuthFailure('Unexpected error: ${e.toString()}'));
      }
    }

  @override
  Future<void> verifyEmail(String email) async {
    
  }

    @override
  Future<Either<AuthFailure, void>> forgotPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email, redirectTo: 'your-app://reset-password'); //need a domain
      return const Right(null);
    } catch (e) {
      if (e is AuthException) {
        return Left(AuthFailure(e.message));
      }
      return Left(AuthFailure('Unexpected error: ${e.toString()}'));
    }
  }
}