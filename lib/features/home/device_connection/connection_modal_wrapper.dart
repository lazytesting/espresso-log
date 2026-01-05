import 'package:espresso_log/features/home/device_connection/connection_cubit.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectionModalWrapper extends StatelessWidget {
  const ConnectionModalWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionCubit, ConnectionState>(
      listener: (context, state) async {
        if (state is ConnectionEstablished || state is ConnectionInitial) {
          final nav = navigatorKey.currentState;
          if (nav == null) return;

          nav.popUntil((route) {
            // If top route is one of ours, pop it and keep going once.
            if (route.settings.name == 'connection_dialog') {
              nav.pop();
              return false;
            }
            return true;
          });
          return;
        }
        if (state is ConnectionConnecting) {
          await showDialog<void>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            useRootNavigator: true,
            routeSettings: RouteSettings(name: 'connection_dialog'),
            builder: (_) => AlertDialog(title: Text('Connecting...')),
          );
        } else {
          await showDialog<void>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            useRootNavigator: true,
            routeSettings: RouteSettings(name: 'connection_dialog'),
            builder: (_) => AlertDialog(title: Text('Paused')),
          );
        }
      },
      child: child,
    );
  }
}
