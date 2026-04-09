import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/repositories/auth_repository.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/services/api_service.dart';
import 'package:cv_mobile/services/connectivity_service.dart';
import 'package:cv_mobile/usecases/auth/login_usecase.dart';
import 'package:cv_mobile/usecases/auth/register_usecase.dart';
import 'package:cv_mobile/usecases/auth/logout_usecase.dart';
import 'package:cv_mobile/usecases/auth/get_current_user_usecase.dart';
import 'package:cv_mobile/usecases/auth/update_profile_usecase.dart';
import 'package:cv_mobile/usecases/cv/get_all_cvs_usecase.dart';
import 'package:cv_mobile/usecases/cv/get_cv_by_id_usecase.dart';
import 'package:cv_mobile/usecases/cv/create_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/update_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/delete_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/duplicate_cv_usecase.dart';

import 'fake_data.dart';

// ── Auth Use Cases ──────────────────────────────────────────
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

// ── CV Use Cases ────────────────────────────────────────────
class MockGetAllCvsUseCase extends Mock implements GetAllCvsUseCase {}
class MockGetCvByIdUseCase extends Mock implements GetCvByIdUseCase {}
class MockCreateCvUseCase extends Mock implements CreateCvUseCase {}
class MockUpdateCvUseCase extends Mock implements UpdateCvUseCase {}
class MockDeleteCvUseCase extends Mock implements DeleteCvUseCase {}
class MockDuplicateCvUseCase extends Mock implements DuplicateCvUseCase {}

// ── Repositories ────────────────────────────────────────────
class MockAuthRepository extends Mock implements AuthRepository {}
class MockCvRepository extends Mock implements CvRepository {}

// ── Services ────────────────────────────────────────────────
class MockApiService extends Mock implements ApiService {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockConnectivityService extends Mock implements ConnectivityService {}

/// Enregistre les fallback values pour tous les types utilises dans les mocks.
/// Doit etre appele dans setUp() de chaque fichier de test.
void registerAllFallbackValues() {
  registerFallbackValue(const LoginParams(email: '', password: ''));
  registerFallbackValue(const RegisterParams(email: '', password: ''));
  registerFallbackValue(const NoParams());
  registerFallbackValue(const UpdateProfileParams());
  registerFallbackValue(fakeCv());
  registerFallbackValue(UpdateCvParams(id: 0, cv: fakeCv()));
}
