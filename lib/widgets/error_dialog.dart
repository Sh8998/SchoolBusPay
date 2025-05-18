import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ErrorDialog extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  State<ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<ErrorDialog> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        try {
                          return Lottie.asset(
                            'assets/animations/error.json',
                            controller: _controller,
                          );
                        } catch (e) {
                          return Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _controller.stop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                    if (widget.onRetry != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _controller.stop();
                          Navigator.of(context).pop();
                          widget.onRetry!();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 