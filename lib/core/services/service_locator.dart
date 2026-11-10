import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../features/users/data/datasources/admin_users_remote_data_source.dart';
import '../../features/users/data/repositories/admin_users_repository_impl.dart';
import '../../features/users/domain/repositories/admin_users_repository.dart';
import '../../features/users/presentation/bloc/admin_users_bloc.dart';
import '../../features/auth/data/datasources/admin_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/admin_auth_repository_impl.dart';
import '../../features/auth/domain/repositories/admin_auth_repository.dart';
import '../../features/auth/presentation/bloc/admin_auth_bloc.dart';
import '../../features/transactions/data/datasources/transactions_remote_data_source.dart';
import '../../features/transactions/data/repositories/transactions_repository_impl.dart';
import '../../features/transactions/domain/repositories/transactions_repository.dart';
import '../../features/transactions/presentation/bloc/transactions_bloc.dart';
import '../../features/products/data/datasources/admin_products_remote_data_source.dart';
import '../../features/products/data/datasources/admin_products_local_data_source.dart';
import '../../features/products/data/repositories/admin_products_repository_impl.dart';
import '../../features/products/domain/repositories/admin_products_repository.dart';
import '../../features/products/presentation/bloc/admin_products_bloc.dart';

final sl = GetIt.instance;

Future<void> initAdminDependencies() async {
  // 1. External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // 2. Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sharedPreferences: sl()));

  // 3. Data Sources
  sl.registerLazySingleton<AdminAuthRemoteDataSource>(
    () => AdminAuthRemoteDataSourceImpl(apiClient: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<AdminUsersRemoteDataSource>(
    () => AdminUsersRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<TransactionsRemoteDataSource>(
    () => TransactionsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AdminProductsLocalDataSource>(
    () => AdminProductsLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<AdminProductsRemoteDataSource>(
    () => AdminProductsRemoteDataSourceImpl(apiClient: sl(), localDataSource: sl()),
  );

  // 4. Repositories
  sl.registerLazySingleton<AdminAuthRepository>(
    () => AdminAuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminUsersRepository>(
    () => AdminUsersRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TransactionsRepository>(
    () => TransactionsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminProductsRepository>(
    () => AdminProductsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // 5. BLoCs
  sl.registerFactory<AdminAuthBloc>(
    () => AdminAuthBloc(authRepository: sl()),
  );
  sl.registerFactory<AdminUsersBloc>(
    () => AdminUsersBloc(repository: sl()),
  );
  sl.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(repository: sl()),
  );
  sl.registerFactory<AdminProductsBloc>(
    () => AdminProductsBloc(repository: sl()),
  );
}
