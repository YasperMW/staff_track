import 'package:flutter/material.dart';
import '../utils/connectivity_handler.dart';
import '../../theme/app_theme.dart';

/// A reusable widget that provides pull-to-refresh functionality
/// with built-in loading, error, and empty states.
class RefreshableContent<T> extends StatefulWidget {
  final Future<T> Function() onRefresh;
  final Widget Function(BuildContext context, T data) builder;
  final T? initialData;
  final Widget? loadingWidget;
  final String? loadingMessage;
  final String? emptyMessage;
  final Widget? emptyWidget;
  final String? errorMessage;
  final VoidCallback? onErrorRetry;
  final bool showErrorSnackBar;
  final EdgeInsetsGeometry? padding;

  const RefreshableContent({
    super.key,
    required this.onRefresh,
    required this.builder,
    this.initialData,
    this.loadingWidget,
    this.loadingMessage,
    this.emptyMessage,
    this.emptyWidget,
    this.errorMessage,
    this.onErrorRetry,
    this.showErrorSnackBar = false,
    this.padding,
  });

  @override
  State<RefreshableContent<T>> createState() => _RefreshableContentState<T>();
}

class _RefreshableContentState<T> extends State<RefreshableContent<T>> {
  T? _data;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _data == null;
      _error = null;
    });

    try {
      final data = await widget.onRefresh();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _error = ConnectivityHandler.getErrorMessage(e);
        });

        if (widget.showErrorSnackBar && mounted) {
          ConnectivityHandler.showErrorSnackBar(
            context,
            message: _error!,
            onRetry: widget.onErrorRetry ?? _loadData,
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading && _data == null) {
      return widget.loadingWidget ??
          LoadingWidget(message: widget.loadingMessage ?? 'Loading...');
    }

    // Error state
    if (_error != null && _data == null) {
      return ConnectivityErrorWidget(
        message: _error!,
        onRetry: widget.onErrorRetry ?? _loadData,
      );
    }

    // Empty state
    if (_data == null || (_data is List && (_data as List).isEmpty)) {
      return widget.emptyWidget ??
          _buildEmptyState(widget.emptyMessage ?? 'No data available');
    }

    // Success state with pull-to-refresh
    return RefreshIndicator(
      color: AppTheme.skyBlue,
      onRefresh: _handleRefresh,
      child: ListView(
        padding: widget.padding ?? EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_error != null)
            ConnectivityErrorWidget(
              message: _error!,
              onRetry: _loadData,
              isCompact: true,
            ),
          widget.builder(context, _data as T),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppTheme.skyBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.skyBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simpler refreshable wrapper for existing scrollable content
/// Use this when you have a CustomScrollView, ListView, or SingleChildScrollView
/// and just want to add pull-to-refresh.
class RefreshableWrapper extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollController? controller;

  const RefreshableWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.controller,
  });

  @override
  State<RefreshableWrapper> createState() => _RefreshableWrapperState();
}

class _RefreshableWrapperState extends State<RefreshableWrapper> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.skyBlue,
      onRefresh: widget.onRefresh,
      child: widget.child,
    );
  }
}

/// A widget that wraps a screen with pull-to-refresh and error handling
/// for simple list/data screens
class RefreshableScreen extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onErrorRetry;
  final bool isLoading;
  final bool hasError;

  const RefreshableScreen({
    super.key,
    required this.onRefresh,
    required this.child,
    this.errorMessage,
    this.onErrorRetry,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    if (hasError && errorMessage != null) {
      return ConnectivityErrorWidget(
        message: errorMessage!,
        onRetry: onErrorRetry ?? onRefresh,
      );
    }

    return RefreshIndicator(
      color: AppTheme.skyBlue,
      onRefresh: onRefresh,
      child: child,
    );
  }
}