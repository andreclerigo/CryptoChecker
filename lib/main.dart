import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_font_icons/crypto_font_icons.dart';
import 'package:flutter/widgets.dart';
import 'binance/binance.dart';

String? selectedCurrency = 'EUR';
Map<String, Color> customColors = {
  'background': Color(0xFF212529),
  'primary': Color(0xFFd9d9d9),
  'secondary': Color(0xFFf94144),
};
Map<String, IconData> currencyIcon = {
  'EUR': Icons.euro,
  'USD': Icons.attach_money,
};
var rest = Binance();
bool firstTime = true;

void main() => runApp(MyApp());

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget({required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class AccountWidget extends StatefulWidget {
  @override
  _AccountState createState() => _AccountState();
}

class BalanceWidget extends StatefulWidget {
  @override
  _BalanceState createState() => _BalanceState();
}

class CurrencyWidget extends StatefulWidget {
  @override
  _CurrencyState createState() => _CurrencyState();
}

// Return a Map with the correct information for the user
Future<Map<String, List<double>>> _getData(AccountInfo? acc) async {
  Map<String, List<double>> coinInfo = {};
  double total = 0;
  double avgPercentage = 0;

  for (Balance b in acc!.balances)
    if (b.free != 0) {
      AveragedPrice avg = await rest.averagePrice(
          '${b.asset}${selectedCurrency == 'USD' ? 'USDT' : selectedCurrency}');
      TickerStats stat = await rest.dailyStats(
          '${b.asset}${selectedCurrency == 'USD' ? 'USDT' : selectedCurrency}');

      coinInfo['${b.asset}'] = [
        avg.price * b.free,
        b.free,
        stat.priceChangePercent
      ];
    }

  coinInfo.forEach((key, value) => total += value.first);
  coinInfo['Total'] = [total];

  coinInfo.forEach((key, value) {
    if (key != 'Total' && key != 'Percent')
      avgPercentage += value[2] * (value.first / total);
  });

  coinInfo['Percent'] = [avgPercentage];

  return coinInfo;
}

// Return the Container with the assets information
Container _printData(Map<String, List<double>> coinInfo) {
  return Container(
    margin: const EdgeInsets.only(bottom: 30),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Generate the Rows with the Assets Infromation
        for (MapEntry entry in coinInfo.entries)
          if (entry.key != 'Total' && entry.key != 'Percent')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(CryptoFontIcons.getIcon('${entry.key}') ?? Icons.help),
                    Text(
                      ' ${entry.key}: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                  ],
                ),
                Text(
                  '${entry.value[1]}\n${(entry.value[0]).toStringAsFixed(2)} $selectedCurrency\n${entry.value[2]} %',
                  style: TextStyle(fontSize: 25),
                ),
              ],
            ),
        // Last Container with the Total Amount on the account
        Container(
          margin: EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              Text(
                '${(coinInfo['Total']!.first).toStringAsFixed(2)} $selectedCurrency',
                style: TextStyle(fontSize: 25),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Check if it's the first time using the app and therefore request the credentials
Future<StatelessWidget> _screenRoute() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? ft = prefs.getBool('firstTime');
  if (ft != null) firstTime = ft;

  if (!firstTime) return Home();
  return AccountPage();
}

// Escape 'No MediaQuery widget found' Error
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<StatelessWidget>(
        future: _screenRoute(),
        builder: (ctx, AsyncSnapshot<StatelessWidget> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return AccountPage();
          } else {
            if (snap.hasData) return snap.data!;
            return AccountPage();
          }
        },
      ),
    );
  }
}

// Displays the Home Page with assets information and both buttons
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // App warpped arround a RestartWidget needed to reload the app properly
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RestartWidget(
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Container(
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: size.height,
                      child: BalanceWidget(),
                    ),
                    Container(
                      // Create the currency button on top right with some padding
                      margin: const EdgeInsets.only(top: 25.0, right: 15.0),
                      alignment: Alignment.topRight,
                      child: CurrencyWidget(),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, left: 15.0),
                      alignment: Alignment.topLeft,
                      child: AccountWidget(),
                    )
                  ],
                ),
              ),
            ),
            backgroundColor: customColors['background'],
          ),
        ),
      ),
    );
  }
}

// Displays the account page to submit the credentials
class AccountPage extends StatelessWidget {
  final apiKey = TextEditingController();
  final secretKey = TextEditingController();

  void dispose() {
    // Clean up the controller when the widget is disposed.
    apiKey.dispose();
    secretKey.dispose();
    secretKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Container(
            child: Text(
              'Account Page',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // API Key TextField
            Container(
              width: 350,
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: apiKey,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  labelText: 'API Key',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Secret Key TextField
            Container(
              margin: const EdgeInsets.all(30),
              width: 350,
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: secretKey,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  labelText: 'Secret Key',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Save button to check the credentials
            Container(
              width: 130,
              height: 58,
              child: ElevatedButton(
                // Sabe button
                child: Text(
                  'Save',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                onPressed: () async {
                  if (await rest.accountExists(
                      DateTime.now().millisecondsSinceEpoch,
                      apiKey.text,
                      secretKey.text)) {
                    // If the account exists then change the FirstTime variable
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('firstTime', false);
                    // Change the Page to Home
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                            'Credentials Valid !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    );
                  } else
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                            'Invalid Credentials !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: customColors['background'],
    );
  }
}

// Account Button to change to AccountPage
class _AccountState extends State<AccountWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 58,
      child: ElevatedButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountPage()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle),
            Text(
              '  Account',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Select currency Button with clickable dropdown
class _CurrencyState extends State<CurrencyWidget> {
  // Change the currency being used every time the function is called
  void _setCurrency() async {
    String curr = '';

    selectedCurrency == 'EUR' ? curr = 'USD' : curr = 'EUR';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', curr);

    if (mounted)
      setState(() {
        selectedCurrency = curr;
      });
  }

  // Save the currency preferences on the device
  void _getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currencyName = prefs.getString('currency');

    if (mounted)
      setState(() {
        if (currencyName != null) selectedCurrency = currencyName;
      });
  }

  // Returns the currency that is not beign used by the user
  String _currencyOption() {
    if (selectedCurrency == 'EUR') return 'USD';
    return 'EUR';
  }

  @override
  void initState() {
    _getCurrency(); // When the widget is created, get the currency preference
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Wrapping the widget on a Theme so it's possible to disable splashColor and highlightColor
      // This is done in order to not see highlight artifacts arround the rounded border of the dropdown menu
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        dividerColor: Colors.transparent,
      ),
      child: Container(
        // Width and position of the button
        width: 130,
        child: Container(
          // Rounded borders on the ExpansionTile
          decoration: BoxDecoration(
            color: customColors['secondary'],
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
              bottom: Radius.circular(30),
            ),
          ),
          child: ExpansionTile(
            iconColor: Colors.black, // Change the color of the arrow
            // First Row with the current currency
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  currencyIcon[selectedCurrency],
                  color: Colors.white,
                ),
                Text(
                  ' $selectedCurrency',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            // Second row with the currency avaible to switch
            children: <Widget>[
              Container(
                height: 45.0,
                child: GestureDetector(
                  // onTap change the currency and reload the App
                  onTap: () {
                    _setCurrency();
                    RestartWidget.restartApp(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        currencyIcon[_currencyOption()],
                        color: Colors.white,
                      ),
                      Text(
                        '${_currencyOption()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Balance Container that displays the asset information
class _BalanceState extends State<BalanceWidget> {
  Timer? timer;

  // Initiate the counter to refresh the App
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
        Duration(minutes: 10), (Timer t) => RestartWidget.restartApp(context));
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the Timer when the widget is disposed
    super.dispose();
  }

  // Auxiliary function to return a LoadingCircle
  SizedBox _myLoadingCircle() {
    return SizedBox(
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(customColors['primary']!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccountInfo>(
      future: rest.accountInfo(DateTime.now().millisecondsSinceEpoch),
      builder: (context, AsyncSnapshot<AccountInfo> snapshot) {
        // While connecting show the LoadingCircle
        if (snapshot.connectionState == ConnectionState.waiting)
          return _myLoadingCircle();
        else
          // Get the Map with the Data
          return FutureBuilder<Map<String, List<double>>>(
            future: _getData(snapshot.data),
            builder: (context, AsyncSnapshot<Map<String, List<double>>> snap) {
              // While connecting show the LoadingCircle
              if (snap.connectionState == ConnectionState.waiting) {
                return _myLoadingCircle();
              } else {
                if (snap.hasError)
                  return Center(
                    child: Text(
                      '${snap.error}',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  );
                // Display the correct information on the Card
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 200),
                      child: Text(
                        '${snap.data!['Percent']!.first > 0 ? '+' : ''}${snap.data!['Percent']!.first.toStringAsFixed(2)}%',
                        style: TextStyle(
                            fontSize: 75,
                            color: snap.data!['Percent']!.first > 0
                                ? Colors.green
                                : Colors.red),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 50),
                        decoration: BoxDecoration(
                          color: customColors['primary'],
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(50),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: _printData(snap.data!),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          );
      },
    );
  }
}
