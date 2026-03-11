/// Direct HTTP caller for Firebase Cloud Functions.
///
/// The `cloud_functions` Flutter/Android SDK (v5.x) integrates App Check at the
/// native layer. When no App Check provider is installed it can block the
/// outgoing HTTP request entirely, meaning the server never receives it. This
/// helper bypasses the SDK completely and POSTs directly to the HTTPS callable
/// endpoint, which is 100% equivalent to what the SDK would send.
library cloud_fn;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _region = 'us-central1';
const _projectId = 'sat-act-battle-royale';
const _baseUrl =
    'https://$_region-$_projectId.cloudfunctions.net';

/// Calls a Firebase Cloud Functions HTTPS callable by name.
///
/// [name]  — the exported function name (e.g. 'joinMatchmaking')
/// [data]  — the payload to send inside `{"data": ...}`
///
/// Returns the value of `result` on success. Throws [CloudFnException] on error.
Future<dynamic> callFn(String name, [Map<String, dynamic>? data]) async {
  // Get the current user's ID token.
  String? idToken;
  try {
    idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    debugPrint('[callFn] $name — idToken present: ${idToken != null}');
  } catch (e) {
    debugPrint('[callFn] $name — getIdToken() threw: $e');
  }

  // Build request body. Always embed the token as _idToken fallback.
  final payload = <String, dynamic>{...?data};
  if (idToken != null) {
    payload['_idToken'] = idToken;
  }

  final uri = Uri.parse('$_baseUrl/$name');
  debugPrint('[callFn] $name — POST $uri');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'data': payload}),
  );

  debugPrint('[callFn] $name — status ${response.statusCode}');
  if (response.statusCode != 200) {
    debugPrint('[callFn] $name — error body: ${response.body}');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode == 200) {
    return body['result'];
  }

  // Firebase callable error shape: {"error": {"status": "...", "message": "..."}}
  final err = body['error'] as Map<String, dynamic>? ?? {};
  throw CloudFnException(
    code: (err['status'] as String? ?? 'unknown').toLowerCase(),
    message: err['message'] as String?,
  );
}

class CloudFnException implements Exception {
  final String code;
  final String? message;

  const CloudFnException({required this.code, this.message});

  @override
  String toString() => 'CloudFnException($code): $message';
}
