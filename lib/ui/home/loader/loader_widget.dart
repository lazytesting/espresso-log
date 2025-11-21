import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoaderWidget extends StatelessWidget {
  final Widget completeWidget;

  const LoaderWidget({super.key, required this.completeWidget});

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<bool>(context);

    return Center(
      child: isLoading ? CircularProgressIndicator() : completeWidget,
    );
  }
}
