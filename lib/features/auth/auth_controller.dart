import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/result.dart';
import '../../domain/enums.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/provider_application.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../shared/providers.dart';

/// Holds the authenticated user and drives router redirects.
///
/// Implemented as a [ChangeNotifier] so `go_router` can listen to it directly
/// via `refreshListenable`.
class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  final AuthRepository _repo;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login({required String email, required String password}) async {
    return _run(() => _repo.login(email: email, password: password));
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required AadiService service,
  }) async {
    return _run(
      () => _repo.register(
        email: email,
        password: password,
        name: name,
        service: service,
      ),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }

  /// Submits (or resubmits) a verification application for [kind]. A plain
  /// user only gains that provider's tools once an admin approves it.
  Future<bool> applyForProvider({
    required ProviderKind kind,
    required List<String> documentPaths,
    String? note,
  }) async {
    final current = _user;
    if (current == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (documentPaths.isEmpty) {
        throw const AppException('Please attach at least one document.');
      }
      final applications = [
        for (final a in current.providerApplications)
          if (a.kind != kind) a,
        ProviderApplication(
          kind: kind,
          status: VerificationStatus.pending,
          submittedAt: DateTime.now(),
          documentPaths: documentPaths,
          note: note,
        ),
      ];
      _user = current.copyWith(providerApplications: applications);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not submit your application. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dev-only: simulates an admin approving a pending application until the
  /// real admin dashboard exists.
  void debugApproveProvider(ProviderKind kind) {
    final current = _user;
    if (current == null) return;
    final applications = [
      for (final a in current.providerApplications)
        if (a.kind == kind)
          a.copyWith(status: VerificationStatus.verified, decidedAt: DateTime.now())
        else
          a,
    ];
    _user = current.copyWith(providerApplications: applications);
    notifyListeners();
  }

  Future<bool> _run(Future<dynamic> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final session = await action();
      _user = session.user as AppUser;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

