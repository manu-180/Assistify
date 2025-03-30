import 'package:taller_ceramica/main.dart';

class ObtenerAlertTrigger {
  Future<int> alertTrigger(String user) async {
    final data = await supabase
        .from('usuarios')
        .select('trigger_alert')
        .eq('fullname', user)
        .single();

    return data["trigger_alert"];
  }
}
