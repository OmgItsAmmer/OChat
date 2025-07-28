import 'package:dartz/dartz.dart';
import 'package:frontend/core/errors/failure.dart';

abstract class AuthRepo {
  Future<Either<AuthFailure, void>> login(String email, String password);

  Future<Either<AuthFailure, void>> signup(String email, String password);

  Future<Either<AuthFailure, void>> logout();

  Future<void> forgotPassword(String email);

  Future<Either<AuthFailure, void>> resetPassword(String email, String password);

  Future<void> verifyEmail(String email);


}