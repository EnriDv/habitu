import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

enum ConnectionStateStatus {
  offline,
  localInternetNoBackend,
  online,
}

class ConnectivityService {
  final _statusController = StreamController<ConnectionStateStatus>.broadcast();
  ConnectionStateStatus _currentStatus = ConnectionStateStatus.offline;
  Timer? _pollingTimer;

  ConnectivityService() {
    _startPolling();
  }

  Stream<ConnectionStateStatus> get statusStream => _statusController.stream;
  ConnectionStateStatus get currentStatus => _currentStatus;

  bool get isOnline => _currentStatus == ConnectionStateStatus.online;

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => checkConnection());
    // Initial async check
    checkConnection();
  }

  Future<ConnectionStateStatus> checkConnection() async {
    ConnectionStateStatus newStatus = ConnectionStateStatus.offline;

    try {
      // 1. Validar conexión del dispositivo (interfaces de red locales activas)
      final interfaces = await NetworkInterface.list();
      if (interfaces.isEmpty) {
        newStatus = ConnectionStateStatus.offline;
      } else {
        // 2. Validar que tengamos resolución DNS y salida a internet general
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 5));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            newStatus = ConnectionStateStatus.localInternetNoBackend;
          }
        } on SocketException {
          newStatus = ConnectionStateStatus.offline;
        } on TimeoutException {
          newStatus = ConnectionStateStatus.offline;
        }

        if (newStatus == ConnectionStateStatus.localInternetNoBackend) {
          // 3. Validar conexión al backend
          try {
            final response = await http
                .get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthCheckEndpoint}'))
                .timeout(const Duration(seconds: 5));
            
            // Si responde de alguna forma (por ej. 200, 401, 404, etc.), significa que el host backend es alcanzable
            newStatus = ConnectionStateStatus.online;
          } catch (_) {
            // El servidor backend no responde, pero tenemos internet
            newStatus = ConnectionStateStatus.localInternetNoBackend;
          }
        }
      }
    } catch (_) {
      newStatus = ConnectionStateStatus.offline;
    }

    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
    }

    return _currentStatus;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _statusController.close();
  }
}
