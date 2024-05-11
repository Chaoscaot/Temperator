import 'package:flutter/material.dart';
import 'package:pool_temp_app/src/messages/message.dart';

class ErrorScreen extends StatelessWidget {
  final ErrorObject errorObject;

  const ErrorScreen({super.key, required this.errorObject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(error()),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: errorObject.onRetry != null
          ? FloatingActionButton(
              onPressed: () => errorObject.onRetry!(context),
              child: const Icon(Icons.refresh),
            )
          : null,
      body: ListView(
        children: [
          Text(errorObject.error),
          Text(errorObject.stackTrace.toString()),
        ],
      ),
    );
  }
}

class ErrorObject {
  final String error;
  final String stackTrace;
  final Function(BuildContext context)? onRetry;

  ErrorObject({required this.error, required this.stackTrace, this.onRetry});
}
