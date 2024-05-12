import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:pool_temp_app/src/messages/message.dart';

class ErrorScreen extends StatefulWidget {
  final ErrorObject errorObject;

  const ErrorScreen({super.key, required this.errorObject});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(error()),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: widget.errorObject.onRetry != null
          ? FloatingActionButton(
              onPressed: () => widget.errorObject.onRetry!(context),
              child: const Icon(Icons.refresh),
            )
          : null,
      body: ListView(
        children: [
          Text(widget.errorObject.error),
          Text(widget.errorObject.stackTrace.toString()),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseCrashlytics.instance.recordError(
        widget.errorObject.error, widget.errorObject.stackTrace,
        fatal: false);
  }
}

class ErrorObject {
  final String error;
  final StackTrace? stackTrace;
  final Function(BuildContext context)? onRetry;

  ErrorObject({required this.error, required this.stackTrace, this.onRetry});
}
