import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String state;

  const LoadingScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state == 'connecting' ? "Connecting..." : "Connection paused",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            if (state == 'connecting')
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  // no logic needed
                },
                child: Text('Reconnect'),
              ),
          ],
        ),
      ),
    );
  }
}
