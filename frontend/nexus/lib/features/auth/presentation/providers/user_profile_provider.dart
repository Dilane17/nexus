import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/auth/data/repositories/user_repository.dart';
import 'package:nexus/shared/models/user_profile.dart';
import 'package:nexus/shared/models/app_enums.dart';

class UserProfileNotifier extends Notifier<AsyncValue<UserProfile?>> {
  UserRepository get _repository => ref.watch(userRepositoryProvider);

  @override
  AsyncValue<UserProfile?> build() => const AsyncValue.data(null);

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile();
      state = AsyncValue.data(profile);
    } on ServerException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } on NetworkException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
      UserProfileNotifier.new,
    );

final profileProvider = Provider<UserProfile?>((ref) {
  final asyncProfile = ref.watch(userProfileProvider);
  return asyncProfile.value;
});

final roleProvider = Provider<UserRole>((ref) {
  return ref.watch(profileProvider)?.role ?? UserRole.user;
});
