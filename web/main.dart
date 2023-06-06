import 'dart:html';
import 'dart:js' as js;
import 'package:app/interop.dart';
import 'package:node_interop/node.dart' hide require;
import 'package:node_interop/path.dart';
import 'package:angular/angular.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'package:app/root_view.template.dart' as root_view;

//import 'main.template.dart' as self;

// @GenerateInjector([
//   ClassProvider(Client, useClass: BrowserClient)
// ])
// const InjectorFactory rootInjector = self.rootInjector$Injector;

void main() {
  //var p = require<Path>('path');
  //window
  //  ..console.info(p.join(process.cwd(), 'foo', 'bar'))
  //  ..alert('Hello, Dart! Electron version: ${process.version}');
  //js.context['sqlite3'] = require2('sqlite3');

  runApp(root_view.RootViewNgFactory, createInjector: ([injector]) {
    return Injector.map({
      Client: new BrowserClient()
    }, injector);
  });
}
