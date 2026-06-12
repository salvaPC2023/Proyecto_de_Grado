import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/user.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/supervisor/create_technician_screen.dart';
import '../presentation/screens/supervisor/create_work_order_screen.dart';
import '../presentation/screens/supervisor/location_report_screen.dart';
import '../presentation/screens/supervisor/supervisor_dashboard_screen.dart';
import '../presentation/screens/supervisor/technician_detail_screen.dart';
import '../presentation/screens/supervisor/technician_list_screen.dart';
import '../presentation/screens/technician/closure_form_screen.dart';
import '../presentation/screens/technician/ot_detail_screen.dart';
import '../presentation/screens/technician/ot_list_screen.dart';
import 'di.dart';

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

class AppRouter {
  static GoRouter router(Ref ref) {
    final authChangeNotifier = _AuthNotifier(ref);
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authChangeNotifier,
      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final isLoginRoute = state.matchedLocation == '/login';

        return authState.when(
          data: (session) {
            if (session == null) return isLoginRoute ? null : '/login';
            if (isLoginRoute) {
              return session.user.role == Role.supervisor
                  ? '/supervisor/home'
                  : '/technician/ots';
            }
            // Role guards
            final loc = state.matchedLocation;
            if (session.user.role == Role.technician && loc.startsWith('/supervisor')) {
              return '/technician/ots';
            }
            if (session.user.role == Role.supervisor && loc.startsWith('/technician')) {
              return '/supervisor/home';
            }
            return null;
          },
          loading: () => null,
          error: (_, __) => '/login',
        );
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

        // Supervisor routes
        GoRoute(path: '/supervisor/home', builder: (_, __) => const SupervisorDashboardScreen()),
        GoRoute(
            path: '/supervisor/create-work-order',
            builder: (_, __) => const CreateWorkOrderScreen()),
        GoRoute(
            path: '/supervisor/technicians',
            builder: (_, __) => const TechnicianListScreen()),
        GoRoute(
            path: '/supervisor/technicians/:id',
            builder: (_, state) =>
                TechnicianDetailScreen(technicianId: state.pathParameters['id']!)),
        GoRoute(
            path: '/supervisor/create-technician',
            builder: (_, __) => const CreateTechnicianScreen()),
        GoRoute(
            path: '/supervisor/ots',
            builder: (_, __) => const SupervisorDashboardScreen()),
        GoRoute(
            path: '/supervisor/ots/:id',
            builder: (_, state) =>
                OtDetailScreen(otId: state.pathParameters['id']!)),
        GoRoute(
            path: '/supervisor/location-report',
            builder: (_, __) => const LocationReportScreen()),

        // Technician routes
        GoRoute(path: '/technician/ots', builder: (_, __) => const OtListScreen()),
        GoRoute(
            path: '/technician/ots/:id',
            builder: (_, state) =>
                OtDetailScreen(otId: state.pathParameters['id']!)),
        GoRoute(
            path: '/technician/ots/:ot_id/steps/:step_id/closure',
            builder: (_, state) => ClosureFormScreen(
                  otId: state.pathParameters['ot_id']!,
                  stepId: state.pathParameters['step_id']!,
                )),

        // Shared route
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    );
  }
}
