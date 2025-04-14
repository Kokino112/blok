import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _buttonEnabled = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 7), () {
      setState(() {
        _buttonEnabled = true;
      });
    });
  }

  void _onContinuePressed() async {
    var box = await Hive.openBox('myBox');
    await box.put('seen_welcome', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "❗OBAVEZNO PROČITAJ❗",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text(
                "RadarBlokada pruža informacije o mogućim promenama toka saobraćaja.\n\n"
                    "Aplikacija ne pripada ni jednom političkom pokretu, već služi kao alat za obaveštavanje "
                    "o trenutnim i nadolazećim blokadama javnih prostora.\n\n"
                    "Novac nam nije cilj ali je neophodan za održavanje servera.\n"
                    "S toga su i reklame koje smo sveli na minimum( 1 dnevno ).\n"
                    "Ukoliko želite da nas podržite, možete TRAJNO ukloniti reklame za 240 dinara.\n "
                    "Hvala.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _buttonEnabled ? _onContinuePressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _buttonEnabled ? "Nastavi" : "Sačekaj...",
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
