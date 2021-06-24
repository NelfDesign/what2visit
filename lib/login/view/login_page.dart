import 'package:flutter/material.dart';
import 'package:what2visit/authentication_repository/authentication_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:what2visit/login/login.dart';
import 'package:what2visit/widgets/curved_widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  static Page page() => const MaterialPage<void>(child: LoginPage());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).backgroundColor,
            Theme.of(context).primaryColor
          ],
        )),
        child: Stack(children: [
          CurvedWidget(
            child: Container(
              padding: const EdgeInsets.only(top: 100, left: 50),
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withOpacity(0.4)],
                ),
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 40,
                  color: Color(0xff6a515e),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 200),
            padding: const EdgeInsets.all(8),
            child: BlocProvider(
              create: (_) =>
                  LoginCubit(context.read<AuthenticationRepository>()),
              child: const LoginForm(),
            ),
          ),
        ]),
      ),
    );
  }
}
