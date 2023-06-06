import 'dart:async';
import 'dart:js' as js;

import 'utils/js.dart';

final js.JsObject _sqlite3 = js.context.callMethod('_electronRequire', ['sqlite3']);

const int openReadonly = 0x00000001;
const int openReadwrite = 0x00000002;
const int openCreate = 0x00000004;

class SqliteException implements Exception {
  final String message;

  SqliteException(this.message);

  @override
  String toString() => 'Sqlite3Exception: $message';
}

class Database {
  final js.JsObject _handle;

  Database._(String filename, int mode, Function callback)
    : _handle = new js.JsObject(_sqlite3['Database'], [filename, mode, callback]);

  /// Opens the database with the given [filename].
  /// 
  /// [mode] can be a combination of [openReadonly], [openReadwrite], and [openCreate].
  /// Defaults to `openReadwrite | openCreate`.
  /// 
  /// Set [filename] to `:memory:` for an in-memory database or to an empty string
  /// for an anonymous disk-based database.
  /// 
  /// Throws an [SqliteException] on failure.
  static Future<Database> open(String filename, [int mode]) async {
    mode ??= openReadwrite | openCreate;

    final completer = new Completer<Database>();

    Database database;
    database = new Database._(filename, mode, js.allowInterop((error) {
      if (error != null) {
        completer.completeError(SqliteException(error.toString()));
      } else {
        completer.complete(database);
      }
    }));

    return completer.future;
  }

  /// Runs the [sql] query with the specified [parameters] and returns all resulting rows.
  /// 
  /// Throws an [SqliteException] on failure.
  Future<List<Map<String, dynamic>>> all(String sql, [Map<String, dynamic> parameters]) async {
    final completer = new Completer<List<Map<String, dynamic>>>();

    _handle.callMethod('all', [
      sql, 
      js.JsObject.jsify(parameters ?? {}),
      js.allowInterop((String error, List rows) {
        if (error != null) {
          completer.completeError(SqliteException(error));
          return;
        }
        
        completer.complete(
          rows
            .cast<js.JsObject>()
            .map((x) => jsToMap(x).cast<String, dynamic>())
            .toList()
        );
      })
    ]);

    return completer.future;
  }

  /// Runs the [sql] query with the specified [parameters] and returns the first resulting row;
  /// 
  /// Throws an [SqliteException] on failure.
  Future<Map<String, dynamic>> get(String sql, [Map<String, dynamic> parameters]) async {
    final completer = new Completer<Map<String, dynamic>>();

    _handle.callMethod('get', [
      sql, 
      js.JsObject.jsify(parameters ?? {}),
      js.allowInterop((String error, js.JsObject row) {
        if (error != null) {
          completer.completeError(SqliteException(error));
          return;
        }
        
        completer.complete(jsToMap(row).cast<String, dynamic>());
      })
    ]);

    return completer.future;
  }

  /// Closes the database.
  /// 
  /// Throws an [SqliteException] on failure.
  Future<void> close() async {
    final completer = new Completer<void>();

    _handle.callMethod('close', [js.allowInterop((error) {
      if (error != null) {
        completer.completeError(SqliteException(error.toString()));
      } else {
        completer.complete();
      }
    })]);

    return completer.future;
  }
}