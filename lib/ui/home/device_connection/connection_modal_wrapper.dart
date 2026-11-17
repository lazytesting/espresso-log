import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
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
            builder: (_) => const ConnectionDialog(paused: false),
          );
        } else {
          await showDialog<void>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            useRootNavigator: true,
            routeSettings: RouteSettings(name: 'connection_dialog'),
            builder: (_) => const ConnectionDialog(paused: true),
          );
        }
      },
      child: child,
    );
  }
}

/// Blocking dialog shown while devices connect or are paused when idle.
class ConnectionDialog extends StatelessWidget {
  final bool paused;

  const ConnectionDialog({super.key, required this.paused});

  @override
  Widget build(BuildContext context) {
    if (paused) {
      return const AlertDialog(
        icon: Icon(Icons.battery_saver_outlined),
        title: Text('Devices paused to save battery'),
        content: Text('Touch the screen to reconnect'),
      );
    }
    return const AlertDialog(
      content: Row(
        children: [
          SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Expanded(child: Text('Connecting to your scale and pressure sensor')),
        ],
      ),
    );
  }
}
