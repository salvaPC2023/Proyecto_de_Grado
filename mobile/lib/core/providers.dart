import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remote/sync_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/technical_location_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/work_order_repository.dart';

// Repository interface providers — concrete implementations are injected via
// ProviderScope.overrides in main.dart (see di.dart for override values).
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => throw UnimplementedError());

final userRepositoryProvider =
    Provider<UserRepository>((ref) => throw UnimplementedError());

final workOrderRepositoryProvider =
    Provider<WorkOrderRepository>((ref) => throw UnimplementedError());

final techLocRepositoryProvider =
    Provider<TechnicalLocationRepository>((ref) => throw UnimplementedError());

final syncServiceProvider =
    Provider<SyncService>((ref) => throw UnimplementedError());
