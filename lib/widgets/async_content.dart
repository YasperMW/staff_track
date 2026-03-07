import 'package:flutter/material.dart';

class AsyncContent extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final Widget Function() builder;
  final Widget? loading;
  final Widget? empty;

  const AsyncContent({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.builder,
    this.loading,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loading ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (isEmpty) {
      return empty ??
          Center(
            child: Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          );
    }

    return builder();
  }
}

