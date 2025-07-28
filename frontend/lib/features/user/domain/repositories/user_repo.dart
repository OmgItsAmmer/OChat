import 'package:dartz/dartz.dart';
import 'package:frontend/core/errors/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRepo {

  Future<Either<Failure, void>> updateUser(User user);

  ///save user data to supabase
  Future<Either<Failure, void>> saveUser(User user);

  ///get user data from supabase
  Future<Either<Failure, User>> getUser(String userId);


}