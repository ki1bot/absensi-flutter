import 'package:go_router/go_router.dart';

import '../features/admin/admin_profile_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/parent/parent_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/school/register_school_screen.dart';
import '../features/students/create_student_screen.dart';
import '../features/students/edit_student_screen.dart';
import '../features/students/student_detail_screen.dart';
import '../features/students/students_screen.dart';
import 'splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterSchoolScreen()),
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(
      path: '/admin/profile',
      builder: (_, _) => const AdminProfileScreen(),
    ),
    GoRoute(path: '/students', builder: (_, _) => const StudentsScreen()),
    GoRoute(
      path: '/students/create',
      builder: (_, _) => const CreateStudentScreen(),
    ),
    GoRoute(
      path: '/students/:id/edit',
      builder: (_, state) {
        return EditStudentScreen(
          studentId: int.parse(state.pathParameters['id']!),
        );
      },
    ),
    GoRoute(
      path: '/students/:id',
      builder: (_, state) {
        return StudentDetailScreen(
          studentId: int.parse(state.pathParameters['id']!),
        );
      },
    ),
    GoRoute(path: '/scanner', builder: (_, _) => const ScannerScreen()),
    GoRoute(path: '/attendances', builder: (_, _) => const AttendanceScreen()),
    GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
  ],
);
