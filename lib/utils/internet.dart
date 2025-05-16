import 'package:connectivity_plus/connectivity_plus.dart';

class Internet {
  Future<bool> hayConexionInternet() async {
    final resultado = await Connectivity().checkConnectivity();
    return resultado != ConnectivityResult.none;
  }
}
