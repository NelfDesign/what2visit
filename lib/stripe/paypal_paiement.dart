import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:what2visit/stripe/paypal_service.dart';

class PaypalPayment extends StatefulWidget {
  final Function? onFinish;
  final double? amount;
  final String? currency;
  final String? symbol;
  final int? decimalDigits;

  PaypalPayment(
      {this.onFinish,
        this.amount,
        this.currency,
        this.symbol,
        this.decimalDigits});

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? checkoutUrl;
  String? executeUrl;
  String? accessToken;
  PaypalServices services = PaypalServices();

  // you can change default currency according to your need
  late Map<dynamic, dynamic> defaultCurrency;

  bool isEnableShipping = false;
  bool isEnableAddress = false;

  String returnURL = 'return.example.com';
  String cancelURL = 'cancel.example.com';

  @override
  void initState() {
    super.initState();
    print("init");
    defaultCurrency = {
      "symbol": widget.symbol,
      "decimalDigits": widget.decimalDigits,
      "symbolBeforeTheNumber": true,
      "currency": widget.currency
    };
    // defaultCurrency = {
    //   "symbol": "USD ",
    //   "decimalDigits": 2,
    //   "symbolBeforeTheNumber": true,
    //   "currency": "USD"
    // };

    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await services.getAccessToken();

        final transactions = getOrderParams();
        final res =
        await services.createPaypalPayment(transactions, accessToken);
        if (res != null) {
          print("res null");
          setState(() {
            checkoutUrl = res["approvalUrl"];
            executeUrl = res["executeUrl"];
          });
          print(checkoutUrl);
          print(executeUrl);
        }
      } catch (e) {
        print('exception: ' + e.toString());
        final snackBar = SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        _scaffoldKey.currentState!.showSnackBar(snackBar);
      }
    });
  }

  // item name, price and quantity

  Map<String, dynamic> getOrderParams() {
    print("order params");

    // checkout invoice details
    String totalAmount = widget.amount.toString();
    print("total amount: $totalAmount");
    String subTotalAmount = totalAmount;
    String shippingCost = '0';
    int shippingDiscountCost = 0;
    String userFirstName = 'Gulshan';
    String userLastName = 'Yadav';
    String addressCity = 'Delhi';
    String addressStreet = 'Mathura Road';
    String addressZipCode = '110014';
    String addressCountry = 'India';
    String addressState = 'Delhi';
    String addressPhoneNumber = '+919990119091';

    List items = [
      {
        "name": "Commande Postocards",
        "quantity": 1,
        "price": totalAmount,
        "currency": defaultCurrency["currency"]
      }
    ];

    Map<String, dynamic> temp = {
      "intent": "sale",
      "payer": {"payment_method": "paypal"},
      "transactions": [
        {
          "amount": {
            "total": totalAmount,
            "currency": defaultCurrency["currency"],
            "details": {
              "subtotal": subTotalAmount,
              "shipping": shippingCost,
              "shipping_discount": ((-1.0) * shippingDiscountCost).toString()
            }
          },
          "description": "The payment transaction description.",
          "payment_options": {
            "allowed_payment_method": "INSTANT_FUNDING_SOURCE"
          },
          "item_list": {
            "items": items,
            if (isEnableShipping && isEnableAddress)
              "shipping_address": {
                "recipient_name": userFirstName + " " + userLastName,
                "line1": addressStreet,
                "line2": "",
                "city": addressCity,
                "country_code": addressCountry,
                "postal_code": addressZipCode,
                "phone": addressPhoneNumber,
                "state": addressState
              },
          }
        }
      ],
      "note_to_payer": "Contact us for any questions on your order.",
      "redirect_urls": {"return_url": returnURL, "cancel_url": cancelURL}
    };
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    print(checkoutUrl);

    if (checkoutUrl != null) {
      // ignore: undefined_prefixed_name
      // ui.platformViewRegistry.registerViewFactory('paypal-payment-html',
      //     (int viewId) {
      //   html.IFrameElement element = html.IFrameElement()
      //     ..width = '640'
      //     ..height = '360'
      //     ..style.border = 'none';
      //   html.window.addEventListener('onbeforeunload', (event) async {
      //     print("onbeforeunload: ${event.toString()}");
      //   });
      //   html.window.addEventListener('blur', (event) async {
      //     print("blur: ${event.toString()}");
      //   });
      //   html.window.addEventListener('click', (event) async {
      //     print("click: ${event.toString()}");
      //   });
      //   html.window.addEventListener('message', (event) {
      //     print(("event: ${event.toString()}"));
      //   });
      //   element.src = checkoutUrl;
      //   element.style.border = 'none';
      //   print('another');
      //   return element;
      // });
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back_ios),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          child: kIsWeb
              ? HtmlElementView(viewType: 'paypal-payment-html')
              : WebView(
            initialUrl: checkoutUrl,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              if (request.url.contains(returnURL)) {
                final uri = Uri.parse(request.url);
                final payerID = uri.queryParameters['PayerID'];
                if (payerID != null) {
                  services
                      .executePayment(executeUrl, payerID, accessToken)
                      .then((id) {
                    widget.onFinish!(id);
                    Navigator.of(context).pop();
                  });
                } else {
                  Navigator.of(context).pop();
                }
                Navigator.of(context).pop();
              }
              if (request.url.contains(cancelURL)) {
                Navigator.of(context).pop();
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Colors.black12,
          elevation: 0.0,
        ),
        body: Center(child: Container(child: CircularProgressIndicator())),
      );
    }
  }
}
