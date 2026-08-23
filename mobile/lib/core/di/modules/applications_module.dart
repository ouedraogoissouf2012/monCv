import 'package:get_it/get_it.dart';

import '../../../features/applications/application/delete_application.dart';
import '../../../features/applications/application/list_applications.dart';
import '../../../features/applications/application/save_application.dart';
import '../../../features/applications/data/application_remote_data_source.dart';
import '../../../features/applications/data/application_repository_impl.dart';
import '../../../features/applications/domain/application_repository.dart';
import '../../../features/applications/presentation/application_list_controller.dart';
import '../../network/api_transport.dart';

/// Candidatures (issue #246) : Clean Architecture, remplace
/// `JobApplicationProvider` (transport direct + etat mutable).
void registerApplicationsModule(GetIt sl) {
  sl.registerFactory<ApplicationRemoteDataSource>(
      () => HttpApplicationRemoteDataSource(sl<ApiTransport>()));
  sl.registerFactory<ApplicationRepository>(
      () => ApplicationRepositoryImpl(sl<ApplicationRemoteDataSource>()));
  sl.registerFactory<ApplicationListController>(
      () => ApplicationListController(
            listApplications:
                ListApplicationsUseCase(sl<ApplicationRepository>()),
            saveApplication:
                SaveApplicationUseCase(sl<ApplicationRepository>()),
            deleteApplication:
                DeleteApplicationUseCase(sl<ApplicationRepository>()),
          ));
}
