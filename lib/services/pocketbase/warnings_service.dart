import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';

class WarningsService {
  Future<List<Map<String, dynamic>>> fetchWarnings() async {
    try {
      final userId = AuthService.getLoggedInUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print("Fetching warnings for user ID: $userId");

      // Use BaseService to fetch warnings with a filter
      final warnings = await BaseService.fetchList(
        'warnings',
        filter: 'user.id="$userId"',
        sort: '-date_issued',
      );

      // Manually fetch expanded data for issued_by
      for (var warning in warnings) {
        if (warning['issued_by'] != null) {
          final issuer =
              await BaseService.fetchOne('users', warning['issued_by']);
          warning['expand'] = {
            'issued_by': issuer,
          };
        }
      }

      print("Fetched warnings: $warnings");
      return warnings;
    } catch (e) {
      print('❌ WarningsService.fetchWarnings() error: $e');
      rethrow;
    }
  }

  Future<bool> acknowledgeWarning(String warningId) async {
    try {
      final userId = AuthService.getLoggedInUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print("Acknowledging warning ID: $warningId for user ID: $userId");

      final result = await BaseService.update(
        'warnings',
        warningId,
        {
          'acknowledged': true,
          'acknowledged_at': DateTime.now().toIso8601String(),
        },
      );

      if (result) {
        print("✅ Warning $warningId acknowledged successfully");
      } else {
        print("❌ Failed to acknowledge warning $warningId");
      }

      return result;
    } catch (e) {
      print('❌ WarningsService.acknowledgeWarning() error: $e');
      rethrow;
    }
  }
}
