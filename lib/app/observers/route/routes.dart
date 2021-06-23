import 'package:flutter/material.dart';
import 'package:what2visit/app/observers/app.dart';
import 'package:what2visit/home/home.dart';
import 'package:what2visit/login/login.dart';

List<Page> onGenerateAppViewPages(AppStatus state, List<Page<dynamic>> pages) {
  switch (state) {
    case AppStatus.authenticated:
      return [HomePage.page()];
    case AppStatus.unauthenticated:
    default:
      return [LoginPage.page()];
  }
}
