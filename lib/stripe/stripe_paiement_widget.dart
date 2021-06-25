import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:stripe_payment/stripe_payment.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'package:what2visit/models/user.dart';
import 'package:what2visit/widgets/button_cta.dart';
import 'package:intl/intl.dart';

class StripePaymentWidget extends StatefulWidget {
  final num? amount;
  final String? passedPaymentId;
  final String? passedPaymentError;
  final User? user;
  final void Function(DocumentReference paymentRef)? onSucceed;

  const StripePaymentWidget(
      this.amount, {
        this.passedPaymentId,
        this.passedPaymentError,
        this.onSucceed,
        this.user
      });

  @override
  State<StatefulWidget> createState() => _StripePaymentWidgetState(
    selectedPaymentMethodId: passedPaymentId!,
  );
}

class _StripePaymentWidgetState extends State<StripePaymentWidget> {
  _StripePaymentWidgetState({
    this.selectedPaymentMethodId,
    this.paymentError,
  });

  List paymentMethods = [];
  String? selectedPaymentMethodId;
  var paymentRef;
  String? paymentStatus;
  String? paymentError;
  String? redirectUrl;

  @override
  void initState() {
    super.initState();
    _listenUserCards();
    if (selectedPaymentMethodId != null) _createPayment();
  }

  Future<void> _createPayment() async {
    if (paymentStatus != null)
      return; // It means a payment is already in progress
    setState(() {
      paymentStatus = "new";
    });
    final data = {
      "payment_method": selectedPaymentMethodId,
      "currency": "EUR",
      "amount": (widget.amount!.toDouble() * 100).round(),
      "status": paymentStatus,
    };

    this.paymentRef = await FirebaseFirestore.instance
        .collection('stripe_customers')
        .doc(widget.user!.id)
        .collection('payments')
        .add(data);

    _listenPayment();
  }

  void _listenPayment() {
    this.paymentRef.snapshots().listen((docSnapshot) {
      setState(() {
        paymentStatus = docSnapshot.data()["status"];
        paymentError = docSnapshot.data()["error"];
        final nextAction = docSnapshot.data()["next_action"];
        if (nextAction != null && nextAction["redirect_to_url"] != null)
          redirectUrl = nextAction["redirect_to_url"]["url"];
        else
          redirectUrl = null;
      });
    });
  }

  void _listenUserCards() {
    FirebaseFirestore.instance
        .collection('stripe_customers')
        .doc(widget.user!.id)
        .collection('payment_methods')
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        paymentMethods = querySnapshot.docs
            .map((e) => e.data()["card"] == null ? null : e.data())
            .toList()
          ..removeWhere((element) => element == null);
        if (paymentMethods.isEmpty) _addNewCard();
      });
    });
  }

  Future<String> _getClientSecret() async {
    final stripeCustomer = await FirebaseFirestore.instance
        .collection('stripe_customers')
        .doc(widget.user!.id)
        .get();
    return stripeCustomer.data()!["setup_secret"];
  }

  void _addNewCard() async {
    StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest())
        .then((paymentMethod) async {
      final clientSecret = await _getClientSecret();
      await StripePayment.confirmSetupIntent(PaymentIntent(
        clientSecret: clientSecret,
        paymentMethodId: paymentMethod.id,
      ));

      await FirebaseFirestore.instance
          .collection("stripe_customers")
          .doc(widget.user!.id)
          .collection("payment_methods")
          .doc(paymentMethod.id)
          .set(paymentMethod.toJson());
    });
  }

  void _confirm3dSecure(String url) async {
    final paymentIntentId = url.split("payment_intent=").last.split("&").first;

    final paymentsRef = FirebaseFirestore.instance
        .collection('stripe_customers')
        .doc(widget.user!.id)
        .collection('payments');

    final paymentSnap =
    await paymentsRef.where("id", isEqualTo: paymentIntentId).get();

    final paymentId = paymentSnap.docs.first.id;
    paymentsRef.doc(paymentId).update({"status": "requires_confirmation"});

    setState(() {
      redirectUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    /*if (redirectUrl != null && paymentStatus == "requires_action")
      return Container(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.all(
            const Radius.circular(20.0),
          ),
          child: WebView(
            initialUrl: redirectUrl,
            javascriptMode: JavascriptMode.unrestricted,
            gestureNavigationEnabled: true,
            navigationDelegate: (NavigationRequest request) {
              if (request.url.contains("test")) {//TODO
                _confirm3dSecure(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      );*/

    final addCardButton = ButtonCTA(
      width: Device.screenWidth,
      title: selectedPaymentMethodId == null
          ? "add new cart"
          : "payment.pay"
          " ${widget.amount}",
      onTap: () {
        selectedPaymentMethodId == null ? _addNewCard() : _createPayment();
      },
    );

    final cardsList = ListView.builder(
        shrinkWrap: true,
        itemCount: paymentMethods.length,
        itemBuilder: (context, index) => GestureDetector(
          child: getCardItem(
              paymentMethods[index]["card"], paymentMethods[index]["id"]),
        ));

    final chooseCardColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
          child: Text(
            paymentMethods.isNotEmpty
                ? "payment.select_credit_card"
                : "payment.no_saved_card",
            style: TextStyle(color: Colors.black54),
          ),
        ),
        Padding(
          child: cardsList,
          padding: EdgeInsets.only(top: 10, bottom: 30),
        ),
        addCardButton,
      ],
    );

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
                "payment.credit_card_payment"),
          ),
          Visibility(
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
            ),
            visible: paymentStatus != "new" && paymentStatus != "succeeded",
          )
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: paymentStatus == null ? chooseCardColumn : paymentProgressWidget,
      ),
    );
  }

  Widget getCardItem(card, paymentMethodId) {
    final expireMonth = card["exp_month"] ?? card["expMonth"];
    final expiredYear = card["exp_year"] ?? card["expYear"];

    final expiredDate = DateTime(expiredYear, expireMonth);
    final dateFormat = DateFormat("MM/yy");

    final deleteCardButton = IconButton(
      icon: Icon(Icons.delete),
      color: Colors.redAccent,
      onPressed: () {
        setState(() {
          selectedPaymentMethodId = null;
        });
        showDialog(
            context: context,
            builder: (BuildContext b) {
              return AlertDialog(
                title:
                Text("payment.delete_card"),
                content: Text(
                    "${"payment.delete_card_confirmation"} "
                        "\"${card["last4"]}\" ?"),
                actions: [
                  TextButton(
                    child: Text("payment.yes"),
                    onPressed: () {
                      Navigator.pop(context);
                      FirebaseFirestore.instance
                          .collection("stripe_customers")
                          .doc(widget.user!.id)
                          .collection("payment_methods")
                          .doc(paymentMethodId)
                          .delete();
                    },
                  ),
                  TextButton(
                    child: Text("payment.no",
                        style: TextStyle(color: Colors.redAccent)),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            });
      },
    );

    return Card(
      elevation: paymentMethodId == selectedPaymentMethodId ? 10 : 2,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.all(5),
        leading: Icon(
          Icons.credit_card,
          color: Colors.blue,
        ),
        trailing: deleteCardButton,
        title: Text(
          "•••• •••• ••••  ${card["last4"]}",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text("${card["brand"]?.toUpperCase()}"),
            Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text("•"),
            ),
            Text("${dateFormat.format(expiredDate)}"),
          ],
        ),
        selected: paymentMethodId == selectedPaymentMethodId,
        selectedTileColor: Color(0xFFDEECF5),
        onTap: () {
          setState(() {
            if (selectedPaymentMethodId == paymentMethodId)
              selectedPaymentMethodId = null;
            else
              selectedPaymentMethodId = paymentMethodId;
          });
        },
      ),
    );
  }

  Widget get paymentProgressWidget {
    String? paymentStatusText;
    Widget? paymentStatusWidget;
    switch (paymentStatus) {
      case "new":
      case "requires_confirmation":
        paymentStatusText =
           "payment.payment_in_progress";
        paymentStatusWidget = Container(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
          height: 25,
          width: 25,
        );
        break;
      case "succeeded":
        paymentStatusText =
            "payment.payment_succeeded";
        paymentStatusWidget = Icon(Icons.check, color: Colors.greenAccent);
        Future.delayed(Duration(milliseconds: 800), () {
          Navigator.pop(context);
          widget.onSucceed!(paymentRef);
        });
        break;
      case "requires_action":
        paymentStatusText =
            "payment.waiting_for_validation";
        paymentStatusWidget = Icon(Icons.send_to_mobile, color: Colors.black38);
        break;
    }

    if (paymentError != null) {
      paymentStatusText =
      "${"payment.payment_failed"} ($paymentError)";
      paymentStatusWidget = Icon(Icons.error, color: Colors.redAccent);
    }

    final retryButton = ButtonCTA(
      title: "payment.retry",
      width: Device.screenWidth * .7,
      onTap: () {
        setState(() {
          selectedPaymentMethodId = null;
          paymentStatus = null;
          paymentError = null;
        });
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              paymentStatusWidget!,
              Expanded(
                child: Padding(
                  child: Text(paymentStatusText!),
                  padding: EdgeInsets.only(left: 12),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          child: retryButton,
          visible: paymentError != null,
        )
      ],
    );
  }
}