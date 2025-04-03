import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EliminarDeBD {
  Future<void> deleteCurrentUser(userUid) async {
    await dotenv.load(fileName: ".env");

    final supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL'] ?? '',
      dotenv.env['SERVICE_ROLE_KEY'] ?? '',
    );

    await supabase.auth.admin.deleteUser(userUid);
  }
}
