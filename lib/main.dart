import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'game_board.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color.fromARGB(255, 12, 33, 219);

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.pressStart2p(
          fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.vt323(
          fontSize: 36, fontWeight: FontWeight.w500, color: Colors.white),
      bodyMedium: GoogleFonts.shareTechMono(fontSize: 16, color: Colors.white),
      labelLarge: GoogleFonts.shareTechMono(fontSize: 18, color: Colors.white),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primarySeedColor,
      scaffoldBackgroundColor: const Color.fromARGB(255, 23, 19, 37),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
        background: const Color.fromARGB(255, 34, 30, 53),
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color.fromARGB(255, 23, 19, 37),
        titleTextStyle: GoogleFonts.pressStart2p(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.shareTechMono(fontSize: 16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color.fromARGB(255, 34, 30, 53),
        titleTextStyle: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
        contentTextStyle: GoogleFonts.shareTechMono(fontSize: 16, color: Colors.white),
      ),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primarySeedColor,
      scaffoldBackgroundColor: const Color.fromARGB(255, 240, 240, 240),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
        background: const Color.fromARGB(255, 255, 255, 255),
      ),
      textTheme: appTextTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        titleTextStyle: GoogleFonts.pressStart2p(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.shareTechMono(fontSize: 16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: GoogleFonts.vt323(fontSize: 24, color: Colors.black),
        contentTextStyle: GoogleFonts.shareTechMono(fontSize: 16, color: Colors.black),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sweeper AI',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _rows = 10;
  int _cols = 10;
  int _mines = 15;
  Key _gameKey = UniqueKey();

  void _showSettingsDialog() {
    final rowsController = TextEditingController(text: _rows.toString());
    final colsController = TextEditingController(text: _cols.toString());
    final minesController = TextEditingController(text: _mines.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rowsController,
              decoration: const InputDecoration(labelText: 'Rows'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: colsController,
              decoration: const InputDecoration(labelText: 'Columns'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: minesController,
              decoration: const InputDecoration(labelText: 'Mines'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final int? newRows = int.tryParse(rowsController.text);
              final int? newCols = int.tryParse(colsController.text);
              final int? newMines = int.tryParse(minesController.text);

              if (newRows != null && newCols != null && newMines != null) {
                if (newMines < newRows * newCols) {
                  setState(() {
                    _rows = newRows;
                    _cols = newCols;
                    _mines = newMines;
                    _gameKey = UniqueKey();
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Number of mines must be less than the total number of cells.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sweeper AI'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SweeperGame(
            key: _gameKey,
            rows: _rows,
            cols: _cols,
            mines: _mines,
          ),
        ),
      ),
    );
  }
}
