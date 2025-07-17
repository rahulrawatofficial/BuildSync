import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/core/routing/router_utils.dart';
import 'package:buildsync/features/admin/presentation/Expenses/add_expenses_page.dart';
import 'package:buildsync/features/admin/presentation/Expenses/edit_expenses_page.dart';
import 'package:buildsync/features/admin/presentation/Expenses/expenses_list_page.dart';
import 'package:buildsync/features/admin/presentation/Tasks/add_task_page.dart';
import 'package:buildsync/features/admin/presentation/admin_dashboard.dart';
import 'package:buildsync/features/admin/presentation/Project/create_project_page.dart';
import 'package:buildsync/features/admin/presentation/Workers/create_worker_page.dart';
import 'package:buildsync/features/admin/presentation/Project/edit_project_page.dart';
import 'package:buildsync/features/admin/presentation/Tasks/edit_task_page.dart';
import 'package:buildsync/features/admin/presentation/Workers/edit_worker_page.dart';
import 'package:buildsync/features/admin/presentation/Tasks/task_list_page.dart';
import 'package:buildsync/features/admin/presentation/Workers/worker_list_page.dart';
import 'package:buildsync/features/auth/presentation/splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
// import '../../features/home/presentation/home_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final location = state.uri.toString();
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = location == '/login';

      if (!isLoggedIn && location != '/login') return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/create-project',
        builder: (context, state) => const CreateProjectPage(),
      ),
      GoRoute(
        path: '/edit-project/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditProjectPage(projectId: id);
        },
      ),
      GoRoute(
        path: '/create-worker',
        builder: (context, state) => const CreateWorkerPage(),
      ),
      GoRoute(
        path: '/worker-list',
        builder: (context, state) => const WorkerListPage(),
      ),
      GoRoute(
        path: '/edit-worker',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final workerId = extra['workerId'] as String;
          final workerData = extra['workerData'] as Map<String, dynamic>;

          return EditWorkerPage(workerId: workerId, workerData: workerData);
        },
      ),
      GoRoute(
        path: '/task-list',
        builder: (context, state) => const TaskListPage(),
      ),
      GoRoute(
        path: '/add-task/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return AddTaskPage(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/edit-task/:projectId/:taskId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          final taskId = state.pathParameters['taskId']!;
          return EditTaskPage(projectId: projectId, taskId: taskId);
        },
      ),
      GoRoute(
        path: '/expense-list',
        builder: (context, state) => const ExpenseListPage(),
      ),
      GoRoute(
        path: '/add-expense/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return AddExpensePage(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/edit-expense/:projectId/:expenseId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          final expenseId = state.pathParameters['expenseId']!;
          return EditExpensePage(projectId: projectId, expenseId: expenseId);
        },
      ),
    ],
  );
}
