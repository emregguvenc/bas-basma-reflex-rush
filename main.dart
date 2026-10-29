import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameStore.instance.load();
  // Initialize MobileAds only after adding your AdMob App ID to AndroidManifest.xml.
  runApp(const ReflexRushApp());
}

const bg = Color(0xFF08080D);
const panel = Color(0xFF15121B);
const red = Color(0xFFFF2448);
const pink = Color(0xFFFF477E);

class ReflexRushApp extends StatelessWidget {
  const ReflexRushApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Bas Basma: Reflex Rush',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: red, brightness: Brightness.dark),
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
    ),
    home: const HomePage(),
  );
}

class GameStore {
  GameStore._();
  static final instance = GameStore._();
  late SharedPreferences prefs;
  int bestClassic = 0, bestLives = 0, coins = 0, games = 0;
  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    bestClassic = prefs.getInt('bestClassic') ?? 0;
    bestLives = prefs.getInt('bestLives') ?? 0;
    coins = prefs.getInt('coins') ?? 0;
    games = prefs.getInt('games') ?? 0;
  }
  Future<void> save() async {
    await prefs.setInt('bestClassic', bestClassic);
    await prefs.setInt('bestLives', bestLives);
    await prefs.setInt('coins', coins);
    await prefs.setInt('games', games);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool sound = true;
  @override
  Widget build(BuildContext context) {
    final s = GameStore.instance;
    return Scaffold(body: SafeArea(child: Stack(children: [
      const Positioned.fill(child: NeonBackdrop()),
      SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 24, 22, 26), child: Column(
        children: [
          Row(children: [
            const Icon(Icons.bolt, color: red, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('REFLEX RUSH', style: TextStyle(fontSize: 17, letterSpacing: 3, fontWeight: FontWeight.w900))),
            IconButton(onPressed: () => setState(() => sound = !sound), icon: Icon(sound ? Icons.volume_up : Icons.volume_off, color: Colors.white70)),
            IconButton(onPressed: () => showDialog(context: context, builder: (_) => const AboutDialog(
              applicationName: 'Bas Basma: Reflex Rush',
              applicationVersion: '1.0.0',
              children: [Text('BAS! komutunda bas, BASMA! komutunda bekle. Tepkini test et!')],
            )), icon: const Icon(Icons.settings_outlined, color: Colors.white70)),
          ]),
          const SizedBox(height: 35),
          Container(
            width: 112, height: 112,
            decoration: BoxDecoration(shape: BoxShape.circle, color: red.withOpacity(.08),
              border: Border.all(color: red, width: 2),
              boxShadow: [BoxShadow(color: red.withOpacity(.28), blurRadius: 35, spreadRadius: 3)]),
            child: const Icon(Icons.flash_on, color: red, size: 62),
          ),
          const SizedBox(height: 20),
          const Text('BAS BASMA', style: TextStyle(fontSize: 37, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const Text('REFLEX RUSH', style: TextStyle(color: red, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 7)),
          const SizedBox(height: 10),
          const Text('Reflekslerini test et. Rekorunu kır.', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 30),
          Row(children: [
            Expanded(child: StatTile(label: 'KLASİK REKOR', value: '${s.bestClassic}', icon: Icons.emoji_events_outlined)),
            const SizedBox(width: 12),
            Expanded(child: StatTile(label: '3 CAN REKORU', value: '${s.bestLives}', icon: Icons.favorite_border)),
          ]),
          const SizedBox(height: 12),
          StatTile(label: 'JETONLAR  •  TOPLAM OYUN', value: '${s.coins}  •  ${s.games}', icon: Icons.stars_rounded, wide: true),
          const SizedBox(height: 24),
          NeonButton(label: 'KLASİK MOD', subtitle: 'Bir hata veya süre bitişi = oyun biter', icon: Icons.bolt, onTap: () => start(context, GameMode.classic)),
          const SizedBox(height: 12),
          NeonButton(label: '3 CAN MODU', subtitle: 'Üç hata hakkın var', icon: Icons.favorite, onTap: () => start(context, GameMode.lives), outlined: true),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white.withOpacity(.18)), minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage())),
            icon: const Icon(Icons.shopping_bag_outlined), label: const Text('AVANTAJ MAĞAZASI'),
          ),
          const SizedBox(height: 18),
          const Text('BAS! → BAS  •  BASMA! → DOKUNMA', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
        ],
      )),
    ])));
  }
  void start(BuildContext c, GameMode m) => Navigator.push(c, MaterialPageRoute(builder: (_) => GamePage(mode: m)));
}

enum GameMode { classic, lives }

class GamePage extends StatefulWidget {
  final GameMode mode;
  const GamePage({super.key, required this.mode});
  @override State<GamePage> createState() => _GamePageState();
}
class _GamePageState extends State<GamePage> {
  final random = Random();
  Timer? timer;
  int score = 0, lives = 3, remainingMs = 1500, roundMs = 1500, bestStreak = 0, streak = 0;
  bool shouldTap = true, started = false, ended = false, shieldUsed = false;
  String message = 'HAZIR MISIN?';
  DateTime? shownAt;
  int bestReaction = 999999;
  bool get livesMode => widget.mode == GameMode.lives;
  double get progress => (remainingMs / max(1, roundMs)).clamp(0.0, 1.0);

  @override void initState() { super.initState(); }
  @override void dispose() { timer?.cancel(); super.dispose(); }

  int durationFor(int value) {
    if (value < 10) return 1500;
    if (value < 20) return 1250;
    if (value < 35) return 1000;
    if (value < 50) return 800;
    if (value < 75) return 650;
    return 500;
  }
  void begin() {
    if (ended) return;
    setState(() { started = true; message = 'HAZIR...'; });
    nextPrompt(initial: true);
  }
  void nextPrompt({bool initial = false}) {
    timer?.cancel();
    if (ended) return;
    roundMs = durationFor(score);
    remainingMs = roundMs;
    shouldTap = random.nextBool();
    shownAt = DateTime.now();
    setState(() { message = shouldTap ? 'BAS!' : 'BASMA!'; });
    const tick = 40;
    timer = Timer.periodic(const Duration(milliseconds: tick), (t) {
      if (!mounted || ended) { t.cancel(); return; }
      setState(() => remainingMs = max(0, remainingMs - tick));
      if (remainingMs <= 0) {
        t.cancel();
        if (shouldTap) mistake('SÜRE DOLDU!');
        else success(timedOutCorrect: true);
      }
    });
  }
  void tap() {
    if (!started) { begin(); return; }
    if (ended) return;
    if (shouldTap) {
      final reaction = DateTime.now().difference(shownAt ?? DateTime.now()).inMilliseconds;
      bestReaction = min(bestReaction, reaction);
      success();
    } else {
      mistake('YANLIŞ HAMLE!');
    }
  }
  void success({bool timedOutCorrect = false}) {
    timer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      score++;
      streak++;
      bestStreak = max(bestStreak, streak);
      message = timedOutCorrect ? 'GÜZEL BEKLEYİŞ!' : 'DOĞRU!';
    });
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted && !ended) nextPrompt(); });
  }
  void mistake(String why) {
    timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      streak = 0;
      if (livesMode && lives > 1) {
        lives--;
        message = why;
      } else {
        if (livesMode) lives = 0;
        finish();
      }
    });
    if (!ended) Future.delayed(const Duration(milliseconds: 650), () { if (mounted && !ended) nextPrompt(); });
  }
  Future<void> finish() async {
    timer?.cancel();
    ended = true;
    started = false;
    final s = GameStore.instance;
    s.games++;
    s.coins += max(1, score ~/ 5);
    if (livesMode) { s.bestLives = max(s.bestLives, score); } else { s.bestClassic = max(s.bestClassic, score); }
    await s.save();
    if (mounted) setState(() => message = 'OYUN BİTTİ');
  }
  Future<void> revive() async {
    // Demo flow: one free second-chance token can be spent. Connect rewarded ad here.
    final s = GameStore.instance;
    if (s.coins < 10) return;
    s.coins -= 10;
    await s.save();
    if (!mounted) return;
    setState(() { ended = false; started = true; lives = 1; message = 'İKİNCİ ŞANS!'; });
    nextPrompt();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: bg, title: Text(livesMode ? '3 CAN MODU' : 'KLASİK MOD', style: const TextStyle(letterSpacing: 2, fontSize: 14)), actions: [
      IconButton(onPressed: () { timer?.cancel(); Navigator.pop(context); }, icon: const Icon(Icons.close)),
    ]),
    body: SafeArea(child: Stack(children: [
      const Positioned.fill(child: NeonBackdrop()),
      Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        Row(children: [
          Expanded(child: StatTile(label: 'SKOR', value: '$score', icon: Icons.bolt)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: livesMode ? 'CAN' : 'REKOR', value: livesMode ? '♥' * lives : '${livesMode ? GameStore.instance.bestLives : GameStore.instance.bestClassic}', icon: Icons.favorite_border)),
        ]),
        const SizedBox(height: 24),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: started ? progress : 1, minHeight: 8, backgroundColor: Colors.white10, color: remainingMs < 400 ? pink : red)),
        const SizedBox(height: 10),
        Text(started ? '${(remainingMs / 1000).toStringAsFixed(2)} sn' : 'REFLEKS TESTİ', style: TextStyle(color: remainingMs < 400 ? pink : Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: tap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: min(MediaQuery.of(context).size.width * .78, 310),
            height: min(MediaQuery.of(context).size.width * .78, 310),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !started ? panel : (shouldTap ? red.withOpacity(.12) : const Color(0xFF171A20)),
              border: Border.all(color: !started ? Colors.white24 : (shouldTap ? red : const Color(0xFF535866)), width: 3),
              boxShadow: [BoxShadow(color: (!started ? red : (shouldTap ? red : Colors.blueGrey)).withOpacity(.22), blurRadius: 36, spreadRadius: 4)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(!started ? Icons.touch_app : (shouldTap ? Icons.flash_on : Icons.pan_tool_alt), size: 52, color: !started ? Colors.white70 : (shouldTap ? red : Colors.white70)),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1, color: !started ? Colors.white : (shouldTap ? pink : Colors.white))),
              const SizedBox(height: 10),
              Text(!started ? 'BAŞLAMAK İÇİN DOKUN' : 'KOMUTA DİKKAT ET', style: const TextStyle(fontSize: 10, letterSpacing: 1.4, color: Colors.white54)),
            ]),
          ),
        ),
        const Spacer(),
        if (ended) ...[
          Text('Skorun: $score   •   En iyi seri: $bestStreak', style: const TextStyle(color: Colors.white70)),
          if (bestReaction < 999999) Text('En iyi tepkin: ${bestReaction} ms', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: NeonButton(label: 'TEKRAR OYNA', icon: Icons.refresh, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GamePage(mode: widget.mode))))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('ANA SAYFA'))),
          ]),
          if (GameStore.instance.coins >= 10) TextButton(onPressed: revive, child: const Text('10 jetonla ikinci şans kazan')),
        ] else
          const Text('BAS! komutunda dokun • BASMA! komutunda bekle', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 12),
      ])),
    ])),
  );
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override State<ShopPage> createState() => _ShopPageState();
}
class _ShopPageState extends State<ShopPage> {
  final iap = InAppPurchase.instance;
  bool available = false;
  @override void initState() { super.initState(); checkStore(); }
  Future<void> checkStore() async { available = await iap.isAvailable(); if (mounted) setState(() {}); }
  Future<void> buy(String id) async {
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Satın alma mağazası şu an kullanılamıyor. Mağaza kimlikleri yapılandırılmalı.')));
      return;
    }
    final products = await iap.queryProductDetails({id});
    if (products.productDetails.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün bulunamadı. Google Play Console ürün kimliğini ekleyin.')));
      return;
    }
    await iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: products.productDetails.first));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AVANTAJ MAĞAZASI')),
    body: Stack(children: [
      const Positioned.fill(child: NeonBackdrop()),
      ListView(padding: const EdgeInsets.all(20), children: [
        StatTile(label: 'JETON BAKİYESİ', value: '${GameStore.instance.coins}', icon: Icons.stars),
        const SizedBox(height: 18),
        ShopItem(title: 'İkinci Şans', desc: '10 jeton karşılığında bir kez devam et.', icon: Icons.favorite, price: '10 jeton', onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('İkinci Şans'), content: const Text('Oyun sonu ekranında 10 jetonla devam edebilirsin. Reklamla ücretsiz devam özelliği, AdMob kimlikleri eklendikten sonra etkinleştirilecek.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('TAMAM'))]))),
        ShopItem(title: 'Neon Tema Paketi', desc: 'Görsel tema paketi. Ürün kimliği Play Console’da tanımlanmalı.', icon: Icons.palette, price: 'Ücretli ürün', onTap: () => buy('neon_theme_pack')),
        ShopItem(title: 'Reklamları Kaldır', desc: 'Tek seferlik satın alma ile reklamları kaldır.', icon: Icons.block, price: 'Ücretli ürün', onTap: () => buy('remove_ads')),
        const SizedBox(height: 10),
        const Text('Not: Satın alma kimlikleri ve AdMob reklam birimleri geliştirici hesabında yapılandırılmadan gerçek ödeme veya reklam gösterilmez.', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    ]),
  );
}

class ShopItem extends StatelessWidget {
  final String title, desc, price;
  final IconData icon;
  final VoidCallback onTap;
  const ShopItem({super.key, required this.title, required this.desc, required this.icon, required this.price, required this.onTap});
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: red.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: red)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Text(price, style: const TextStyle(color: pink, fontWeight: FontWeight.bold)),
      ])),
      IconButton(onPressed: onTap, icon: const Icon(Icons.chevron_right, color: red)),
    ]),
  );
}

class StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool wide;
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.wide = false});
  @override Widget build(BuildContext context) => Container(
    width: wide ? double.infinity : null, padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withOpacity(.08))),
    child: Row(children: [
      Icon(icon, color: red, size: 23), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1.1)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ])),
    ]),
  );
}

class NeonButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  const NeonButton({super.key, required this.label, this.subtitle, required this.icon, required this.onTap, this.outlined = false});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, child: Material(
    color: outlined ? panel : red, borderRadius: BorderRadius.circular(17),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: outlined ? red.withOpacity(.65) : pink.withOpacity(.7)), boxShadow: outlined ? [] : [BoxShadow(color: red.withOpacity(.18), blurRadius: 18)]),
      child: Row(children: [
        Icon(icon, color: outlined ? pink : Colors.white, size: 26), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15)),
          if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 10))],
        ])),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
      ]),
    )),
  ));
}

class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key});
  @override Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: BackdropPainter(), child: const SizedBox.expand()));
}
class BackdropPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..shader = RadialGradient(colors: [const Color(0xFF30101A).withOpacity(.55), bg], radius: .95).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, p);
    final line = Paint()..color = red.withOpacity(.045)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 36) canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    for (double x = 0; x < size.width; x += 36) canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
