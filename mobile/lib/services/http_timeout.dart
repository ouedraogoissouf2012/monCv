import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as base;

export 'package:http/http.dart'
    hide delete, get, head, patch, post, put, read, readBytes;

const requestTimeout = Duration(seconds: 20);

Future<T> withRequestTimeout<T>(Future<T> request, {Duration? timeout}) =>
    request.timeout(timeout ?? requestTimeout);

Future<base.Response> get(Uri url, {Map<String, String>? headers}) =>
    withRequestTimeout(base.get(url, headers: headers));

Future<base.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) =>
    withRequestTimeout(
        base.post(url, headers: headers, body: body, encoding: encoding));

Future<base.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) =>
    withRequestTimeout(
        base.put(url, headers: headers, body: body, encoding: encoding));

Future<base.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) =>
    withRequestTimeout(
        base.delete(url, headers: headers, body: body, encoding: encoding));
