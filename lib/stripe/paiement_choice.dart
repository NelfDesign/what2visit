import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:what2visit/models/user.dart';
import 'package:what2visit/stripe/stripe_paiement_widget.dart';

class PaymentChoice extends StatefulWidget {
  final num? amount;
  final User? user;
  final void Function(DocumentReference paymentRef)? onSucceed;

  PaymentChoice({
    @required this.amount,
    this.onSucceed,
    this.user,
  });

  @override
  State<StatefulWidget> createState() => _PaymentChoiceState();
}

class _PaymentChoiceState extends State<PaymentChoice> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    StripePayment.setOptions(StripeOptions(
      publishableKey:
      "pk_test_51J5BGiGmvQOSGWTD6xbg4hBToWASlRQ477lUhFUMKk45J2JALChPqtQ4kxDGOfSf1nllFV2fYXXCvWVkmZggarGJ00czXvHnCm",
      merchantId: "test",
      androidPayMode: "test",
    ));
  }

  void validOrder(DocumentReference paymentRef) {
    widget.onSucceed!(paymentRef);
  }

  @override
  Widget build(BuildContext context) {
    final loadingView = SafeArea(
      child: Container(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );

    final googlePayChoice = ListTile(
        leading: Image.asset(
          "assets/google.png",
          width: 25,
        ),
        title: Text("Payer avec Google Pay"),
        onTap: () => _paymentRequestWithNativePay(context, widget.amount!));

    final applePayChoice = ListTile(
        leading: Image.asset(
          "assets/apple.png",
          width: 25,
        ),
        title: Text("Payer avec Apple Pay"),
        onTap: () => _paymentRequestWithNativePay(context, widget.amount!));

    /*final paypalChoice = ListTile(
        leading: Image.asset(
          "assets/paypal.jpg",
          width: 35,
        ),
        title: Text("Payer avec PayPal"),
        onTap: () async {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => PaypalPayment(
                onFinish: (number) async {
                  // payment done
                  if (number != null) {
                    final data = {
                      "id": number,
                      "status": "succeeded",
                      "error": null,
                    };

                    final paymentRef = await FirebaseFirestore.instance
                        .collection('paypal_customers')
                        .doc(widget.user!.id)
                        .collection('payments')
                        .add(data);

                    paymentRef.snapshots().listen((docSnapshot) {
                      var toto = docSnapshot.data()!["status"];
                      if (docSnapshot.data()!["status"] == "succeeded") {
                        validOrder(paymentRef);
                      }
                      if (docSnapshot.data()!["error"] != null) {
                        Navigator.pop(context);
                        showPaymentError(context);
                        setState(() => loading = false);
                      }
                    });
                  }
                },
                amount: widget.amount!.toDouble(),
                currency: 'EUR',
                symbol: "€",
                decimalDigits: 3,
              ),
            ),
          );
        });*/

    final creditCardChoice = ListTile(
        leading: Image.asset(
          "assets/credit-card.png",
          width: 25,
        ),
        title: Text("Payer par carte"),
        onTap: () async {
          Navigator.pop(context);
          _requestStripePayment(widget.amount!);
        });

    final paymentChoiceView = Container(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          creditCardChoice,
          Platform.isAndroid
              ? googlePayChoice
              : Platform.isIOS
              ? applePayChoice
              : SizedBox(height: 0),
         // paypalChoice,
        ],
      ),
    );

    return loading ? loadingView : paymentChoiceView;
  }

  Future<void> _requestStripePayment(num amount,
      {String? paymentMethodId}) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext b) {
          return StripePaymentWidget(
            amount,
            passedPaymentId: paymentMethodId!,
            onSucceed: validOrder,
          );
        });
  }

  void _paymentRequestWithNativePay(BuildContext context, num amount) async {
    if (Platform.isIOS) {
      Navigator.pop(context); //Use native view from apple pay
    } else {
      setState(() => loading = true);
    }

    try {

      final token = await StripePayment.paymentRequestWithNativePay(
        androidPayOptions: AndroidPayPaymentRequest(
          totalPrice: "${widget.amount}",
          currencyCode: "EUR",
        ),
        applePayOptions: ApplePayPaymentOptions(
          countryCode: "FR",
          currencyCode: "EUR",
          items: [
            ApplePayItem(
              label: 'test',
              amount: "${widget.amount}",
            )
          ],
        ),
      );

      final paymentMethod = await StripePayment.createPaymentMethod(
          PaymentMethodRequest(
              card: CreditCard(token: token.tokenId), token: token));

      if (paymentMethod == null) {
        showPaymentError(context);
        return;
      }

      final data = {
        "payment_method": paymentMethod.id,
        "currency": "EUR",
        "amount": (amount * 100).round(),
        "status": "new",
      };

      final paymentRef = await FirebaseFirestore.instance
          .collection('stripe_customers')
          .doc(widget.user!.id)
          .collection('payments')
          .add(data);

      paymentRef.snapshots().listen((docSnapshot) {
        if (docSnapshot.data()!["status"] == "succeeded") {
          StripePayment.completeNativePayRequest();
          validOrder(paymentRef);
          if (!Platform.isIOS) Navigator.pop(context);
          setState(() => loading = false);
        }
        if (docSnapshot.data()!["error"] != null) {
          if (!Platform.isIOS) {
            Navigator.pop(context);
            showPaymentError(context);
          }
          setState(() => loading = false);
        }
      });
    } catch (error) {
      if (!Platform.isIOS) Navigator.pop(context);
      setState(() => loading = false);
    }
  }

  void showPaymentError(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext b) {
          return AlertDialog(
            title: Text("error_title"),
            content:
            Text("payment.payment_error"),
            actions: [
              TextButton(
                  child: Text("Ok"), onPressed: () => Navigator.pop(context))
            ],
          );
        });
  }
}