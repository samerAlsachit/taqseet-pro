import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/logger/app_logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription? _subscription;
  bool _isConnected = true;

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get isConnected => _isConnected;

  void init() {
    _connectivity.checkConnectivity().then((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      _controller.add(_isConnected);
    });
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      _controller.add(_isConnected);
    });
    AppLogger.info('ConnectivityService initialized');
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
