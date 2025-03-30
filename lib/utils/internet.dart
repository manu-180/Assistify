import 'package:connectivity_plus/connectivity_plus.dart';

class Internet {
  Future<bool> hayConexionInternet() async {
    try {
      // Obtén la lista de resultados de conectividad
      final List<ConnectivityResult> resultados =
          await Connectivity().checkConnectivity();

      // Verifica si al menos una conexión es móvil o Wi-Fi
      return resultados.any((resultado) =>
          resultado == ConnectivityResult.mobile ||
          resultado == ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }
}
