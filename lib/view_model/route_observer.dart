import 'package:flutter/widgets.dart';

/// Global RouteObserver used to notify screens when they become visible again.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
