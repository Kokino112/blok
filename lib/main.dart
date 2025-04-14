import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:blokade/map/map_screen.dart';
import 'package:blokade/calendar/calendar_screen.dart';
import 'package:blokade/calendar/welcomescreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await MobileAds.instance.initialize();

  var box = await Hive.openBox('myBox');
  bool seenWelcome = box.get('seen_welcome', defaultValue: false);

  runApp(MyApp(showWelcome: true));
}

class MyApp extends StatelessWidget {
  final bool showWelcome;
  const MyApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.red,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.black,
            fontSize: 14,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.white,
          backgroundColor: Colors.black,
        ),
      ),
      home: showWelcome ? WelcomeScreen() : HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _screens = [MapScreen(), CalendarScreen()];

  late BannerAd _bannerAd;
  bool _isBannerReady = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _showDailyInterstitialAd();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  void _showDailyInterstitialAd() async {
    var box = await Hive.openBox('myBox');
    DateTime? lastShown = box.get('lastInterstitialShown') != null
        ? DateTime.tryParse(box.get('lastInterstitialShown'))
        : null;

    DateTime now = DateTime.now();
    bool shouldShow = lastShown == null || now.difference(lastShown).inHours >= 24;

    if (shouldShow) {
      InterstitialAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) => ad.dispose(),
              onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
            );
            ad.show();
            box.put('lastInterstitialShown', now.toIso8601String());
          },
          onAdFailedToLoad: (error) {
            print('Interstitial failed to load: $error');
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAdButton(String text) {
    bool isWhy = text.contains("Zašto");
    bool isRemove = text.contains("Ugasi");

    return GestureDetector(
      onTap: () async {
        if (isWhy) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black,
              title: Text("Zašto reklame?", style: TextStyle(color: Colors.white)),
              content: Text(
                "Ova aplikacija je potpuno besplatna. "
                    "Reklame su jedini način da pokrijemo troškove održavanja servera i svakodnevnog angažovanja.\n\n"
                    "Broj oglasa smo sveli na minimum – jedan dnevno.\n \n"
                    "Ukoliko želiš da nas podržiš, možeš ih trajno ukloniti simboličnom donacijom od 240 din. Hvala <3",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Razumem", style: TextStyle(color: Colors.redAccent)),
                )
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("Uklanjanje reklama", style: TextStyle(color: Colors.redAccent)),
              content: Text("Želite li da uklonite reklame za 240 RSD?", style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Otkaži", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    var box = await Hive.openBox('myBox');
                    await box.put('ads_removed', true);
                    setState(() {
                      _isBannerReady = false;
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Plati"),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            if (isRemove)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text("❤️", style: TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAdButton("Ugasi reklame"),
            IconButton(
              icon: Image.asset(
                'lib/assets/bloody_icon_padded.png',
                width: 40,
                height: 40,
              ),
              onPressed: () {},
            ),
            _buildAdButton("Zašto reklame ?"),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isBannerReady ? 42.0 : 0),
          child: _isBannerReady
              ? Align(
            alignment: Alignment.center,
            child: Container(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
          )
              : SizedBox.shrink(),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white38,
              spreadRadius: 0,
              blurRadius: 0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "Mapa live",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: "Najave",
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
