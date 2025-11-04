import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int initialRows;
  final int initialCols;
  final int initialMines;

  const SettingsScreen({
    super.key,
    required this.initialRows,
    required this.initialCols,
    required this.initialMines,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _rows;
  late double _cols;
  late double _mines;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows.toDouble();
    _cols = widget.initialCols.toDouble();
    _mines = widget.initialMines.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Rows: ${_rows.toInt()}'),
            Slider(
              value: _rows,
              min: 2,
              max: 25,
              divisions: 24,
              label: _rows.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _rows = value;
                  if (_mines > (_rows * _cols) - 1) {
                    _mines = (_rows * _cols) - 1;
                  }
                });
              },
            ),
            SizedBox(height: 20),
            Text('Columns: ${_cols.toInt()}'),
            Slider(
              value: _cols,
              min: 2,
              max: 25,
              divisions: 24,
              label: _cols.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _cols = value;
                  if (_mines > (_rows * _cols) - 1) {
                    _mines = (_rows * _cols) - 1;
                  }
                });
              },
            ),
            SizedBox(height: 20),
            Text('Mines: ${_mines.toInt()}'),
            Slider(
              value: _mines,
              min: 1,
              max: (_rows * _cols) - 1,
              divisions: (_rows.toInt() * _cols.toInt()) - 1,
              label: _mines.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _mines = value;
                });
              },
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'rows': _rows.toInt(),
                  'cols': _cols.toInt(),
                  'mines': _mines.toInt(),
                });
              },
              child: Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
