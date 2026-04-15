import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Utility class for handling API connectivity errors and displaying
/// user-friendly error messages with retry functionality.
class ConnectivityHandler {
  ConnectivityHandler._();

  /// Maps an exception to a user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings and try again.';
    }
    if (error is HttpException) {
      return 'Server is currently unavailable. Please try again later.';
    }
    if (error is FormatException) {
      return 'Unable to process server response. Please try again.';
    }
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your connection and try again.';
    }
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused') ||
          errorString.contains('network unreachable')) {
        return 'No internet connection. Please check your network settings and try again.';
      }
      if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return 'Connection timed out. Please check your connection and try again.';
      }
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        return 'Your session has expired. Please log in again.';
      }
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        return 'You do not have permission to perform this action.';
      }
      if (errorString.contains('404') || errorString.contains('not found')) {
        return 'The requested resource was not found.';
      }
      if (errorString.contains('500') || errorString.contains('internal server error')) {
        return 'Server error occurred. Please try again later.';
      }
      if (errorString.contains('503') || errorString.contains('service unavailable')) {
        return 'Service is temporarily unavailable. Please try again later.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Checks if the error is a connectivity-related issue
  static bool isConnectivityError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network unreachable') ||
        errorString.contains('timeout') ||
        errorString.contains('timed out');
  }

  /// Shows a connectivity error dialog with retry option
  static void showErrorDialog(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    String retryText = 'Retry',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.paleRed, size: 28),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (isConnectivityError(message)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.skyBlue, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tip: Check your WiFi or mobile data connection',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.skyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(retryText),
            ),
        ],
      ),
    );
  }

  /// Shows a connectivity error snackbar with retry option
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.paleRed,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// A widget that displays an error state with retry functionality
class ConnectivityErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isCompact;

  const ConnectivityErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.paleRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.paleRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: AppTheme.paleRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.paleRed,
                  fontSize: 13,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.paleRed,
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.paleRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: AppTheme.paleRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.skyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays a loading state
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.skyBlue,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}