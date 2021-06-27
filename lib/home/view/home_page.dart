import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:what2visit/app/observers/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:what2visit/home/home.dart';
import 'package:what2visit/stripe/paiement_choice.dart';


class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static Page page() => const MaterialPage<void>(child: HomePage());

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = context.select((AppBloc bloc) => bloc.state.user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            key: const Key('homePage_logout_iconButton'),
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => context.read<AppBloc>().add(AppLogoutRequested()),
          )
        ],
      ),
      body: Align(
        alignment: const Alignment(0, -1 / 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Avatar(photo: user.photo),
            const SizedBox(height: 4.0),
            Text(user.email ?? '', style: textTheme.headline6),
            const SizedBox(height: 4.0),
            Text(user.name ?? '', style: textTheme.headline5),
            const SizedBox(height: 20,),
            ElevatedButton(
                onPressed: () async {
                  showModalBottomSheet(
                      context: context,
                      builder: (BuildContext buildContext) =>
                          PaymentChoice(
                            amount: 20,
                            user: user,
                            onSucceed: (paymentRef) {
                              SchedulerBinding.instance!
                                  .addPostFrameCallback((_) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder: (context) {
                                          return HomePage();
                                        }));
                              });
                            },
                          ));
                },
                child: Text('pay 20'))
          ],
        ),
      ),
    );
  }
}