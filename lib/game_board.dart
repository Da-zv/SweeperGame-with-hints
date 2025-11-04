import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_keys.dart';

class Cell {
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int adjacentMines = 0;
}

class SweeperGame extends StatefulWidget {
  final int rows;
  final int cols;
  final int mines;

  const SweeperGame({
    super.key,
    required this.rows,
    required this.cols,
    required this.mines,
  });

  @override
  SweeperGameState createState() => SweeperGameState();
}

class SweeperGameState extends State<SweeperGame> {
  late List<List<Cell>> board;
  bool gameOver = false;
  bool gameWon = false;
  late Stopwatch _stopwatch;
  late Timer _timer;
  bool _isFetchingHint = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _initializeBoard();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(SweeperGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows ||
        oldWidget.cols != widget.cols ||
        oldWidget.mines != widget.mines) {
      _initializeBoard();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _initializeBoard() {
    board = List.generate(
        widget.rows, (_) => List.generate(widget.cols, (_) => Cell()));
    gameOver = false;
    gameWon = false;
    _stopwatch.reset();

    // Place mines randomly
    Random random = Random();
    int minesPlaced = 0;
    while (minesPlaced < widget.mines) {
      int row = random.nextInt(widget.rows);
      int col = random.nextInt(widget.cols);
      if (!board[row][col].isMine) {
        board[row][col].isMine = true;
        minesPlaced++;
      }
    }

    // Calculate adjacent mines
    for (int row = 0; row < widget.rows; row++) {
      for (int col = 0; col < widget.cols; col++) {
        if (!board[row][col].isMine) {
          int count = 0;
          for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
              if (row + i >= 0 &&
                  row + i < widget.rows &&
                  col + j >= 0 &&
                  col + j < widget.cols) {
                if (board[row + i][col + j].isMine) {
                  count++;
                }
              }
            }
          }
          board[row][col].adjacentMines = count;
        }
      }
    }
  }

  void _revealCell(int row, int col) {
    if (gameOver ||
        gameWon ||
        board[row][col].isRevealed ||
        board[row][col].isFlagged) {
      return;
    }

    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }

    setState(() {
      board[row][col].isRevealed = true;

      if (board[row][col].isMine) {
        gameOver = true;
        _stopwatch.stop();
        _revealAllMines();
        return;
      }

      if (board[row][col].adjacentMines == 0) {
        _revealNeighbors(row, col);
      }
      _checkWinCondition();
    });
  }

  void _revealNeighbors(int row, int col) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int neighborRow = row + i;
        int neighborCol = col + j;
        if (neighborRow >= 0 &&
            neighborRow < widget.rows &&
            neighborCol >= 0 &&
            neighborCol < widget.cols) {
          if (!board[neighborRow][neighborCol].isRevealed) {
            _revealCell(neighborRow, neighborCol);
          }
        }
      }
    }
  }

  void _flagCell(int row, int col) {
    if (gameOver || gameWon || board[row][col].isRevealed) {
      return;
    }
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    setState(() {
      board[row][col].isFlagged = !board[row][col].isFlagged;
    });
  }

  void _checkWinCondition() {
    int revealedCount = 0;
    for (int row = 0; row < widget.rows; row++) {
      for (int col = 0; col < widget.cols; col++) {
        if (board[row][col].isRevealed && !board[row][col].isMine) {
          revealedCount++;
        }
      }
    }
    if (revealedCount == (widget.rows * widget.cols) - widget.mines) {
      setState(() {
        gameWon = true;
        _stopwatch.stop();
        _flagAllMines();
      });
    }
  }

  void _revealAllMines() {
    for (int i = 0; i < widget.rows; i++) {
      for (int j = 0; j < widget.cols; j++) {
        if (board[i][j].isMine) {
          board[i][j].isRevealed = true;
        }
      }
    }
  }

  void _flagAllMines() {
    for (int i = 0; i < widget.rows; i++) {
      for (int j = 0; j < widget.cols; j++) {
        if (board[i][j].isMine) {
          board[i][j].isFlagged = true;
        }
      }
    }
  }

  Future<void> getHint() async {
    if (_isFetchingHint) return;

    setState(() {
      _isFetchingHint = true;
    });

    if (groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('API Key Missing'),
            content: const Text(
                'Please add your Groq API key to lib/api_keys.dart to use the hint feature.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      setState(() {
        _isFetchingHint = false;
      });
      return;
    }

    try {
      final prompt = _createAIPrompt();

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen/qwen3-32b',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.6,
          'max_completion_tokens': 2048,
          'top_p': 0.95,
          'reasoning_effort': "none",
        }),
      );

      String hintText = 'No suggestion from AI.';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        hintText = data['choices'][0]['message']['content'] ?? hintText;
      } else {
        developer.log(
            'Groq API Error: ${response.statusCode}\n${response.body}');
        hintText =
            'Error communicating with the AI. Status code: ${response.statusCode}';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Hint'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hintText),
                  const SizedBox(height: 20),
                  //const Text("Prompt:",
                  //    style: TextStyle(fontWeight: FontWeight.bold)),
                  //const SizedBox(height: 8),
                  //Text(prompt),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e, s) {
      developer.log(
        'Error getting AI hint',
        name: 'SweeperGame',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not get a hint from the AI. Please try again.'),
          ),
        );
      }
    }

    setState(() {
      _isFetchingHint = false;
    });
  }

  String _createAIPrompt() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln(
        '''You are an assistant that analyzes a Minesweeper game grid and suggests the safest next move. Game Grid Format
          - The grid includes row and column headers.
          - The first row lists column numbers (c1, c2, c3, ...).
          - The first column lists row numbers (r1, r2, r3, ...).
          - Each cell contains one of the following symbols:
          - "." → Unrevealed cell (unknown, could be mine or safe)
          - "F" → Flagged cell (believed to contain a mine)
          - A number (0–8) → Revealed cell showing how many mines are adjacent (including diagonals)

          Example grid:
            c1 c2 c3 c4
          r1 1  1  0  0
          r2 .  .  1  1
          r3 .  .  F  1
          r4 .  .  .  1

          ## Task
          1. Analyze the current game grid logically as in standard Minesweeper rules.
          2. Identify **which unrevealed cell(s)** (represented by '.') are **safe to reveal next**.
          3. If no safe move can be guaranteed, identify **the cell(s) with the lowest probability of containing a mine**, and explain why.
          4. Output should include:
            - Safe cell(s) to reveal next (by row and column label, example. "r2c1").
            - Reasoning or logical explanation for why the cell is safe.
            - Optional: Cells that are likely mines but not yet flagged.
            - Optional: Cells that are uncertain (guessing required).

          ## Output Format
          Use this format for clarity:

          Safe to reveal next:
          - r2c1 — Safe because adjacent number 1 already has one flagged mine, so this must be clear.

          Possible mines:
          - r3c2 — Likely a mine based on adjacency counts.

          Now analyze the following grid and keep the answers short:''');
    // Add column headers
    String colHeader = '   '; // Space for row headers
    for (int j = 0; j < widget.cols; j++) {
      colHeader += ' ${j.toString().padLeft(2, ' ')} ';
    }
    buffer.writeln(colHeader);

    for (int i = 0; i < widget.rows; i++) {
      String rowStr = '${i.toString().padLeft(2, ' ')} ';
      for (int j = 0; j < widget.cols; j++) {
        Cell cell = board[i][j];
        if (cell.isFlagged) {
          rowStr += ' F  ';
        } else if (!cell.isRevealed) {
          rowStr += ' .  ';
        } else if (cell.isMine) {
          rowStr +=
              ' *  '; // Should not happen in a normal game state sent to AI
        } else {
          rowStr += ' ${cell.adjacentMines}  ';
        }
      }
      buffer.writeln(rowStr);
    }

    return buffer.toString();
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              color: theme.colorScheme.background.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text('Mines', style: theme.textTheme.labelSmall),
                  Text(widget.mines.toString(),
                      style: theme.textTheme.titleSmall),
                ],
              ),
              Column(
                children: [
                  Text('Time', style: theme.textTheme.labelSmall),
                  Text(
                    _formatTime(_stopwatch.elapsed),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (gameOver)
          Text('Game Over!',
              style: theme.textTheme.displayLarge?.copyWith(color: Colors.red)),
        if (gameWon)
          Text('You Win!',
              style:
                  theme.textTheme.displayLarge?.copyWith(color: Colors.green)),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double cellSize = min(
                  (constraints.maxWidth - 30) / widget.cols, // -30 for row headers
                  (constraints.maxHeight - 30) /
                      widget.rows, // -30 for col headers
                );

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Column Headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                            width: 30), // Placeholder for row header column
                        ...List.generate(widget.cols, (col) {
                          return SizedBox(
                            width: cellSize,
                            height: 30, // Header height
                            child: Center(
                              child: Text(
                                '${col}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Row Headers
                        Column(
                          children: List.generate(widget.rows, (row) {
                            return SizedBox(
                              width: 30, // Header width
                              height: cellSize,
                              child: Center(
                                child: Text(
                                  '${row}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            );
                          }),
                        ),
                        // Game Board
                        SizedBox(
                          width: cellSize * widget.cols,
                          height: cellSize * widget.rows,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.cols,
                              ),
                              itemCount: widget.rows * widget.cols,
                              itemBuilder: (context, index) {
                                int row = index ~/ widget.cols;
                                int col = index % widget.cols;
                                Cell cell = board[row][col];

                                return GestureDetector(
                                  onTap: () => _revealCell(row, col),
                                  onLongPress: () => _flagCell(row, col),
                                  onSecondaryTap: () => _flagCell(row, col),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color:
                                          _getCellColor(cell, Theme.of(context)),
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          width: 0.5),
                                    ),
                                    child: Center(
                                      child: _buildCellContent(
                                          cell, Theme.of(context)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_isFetchingHint)
          const CircularProgressIndicator()
        else
          ElevatedButton.icon(
            onPressed: getHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Get a Hint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getCellColor(Cell cell, ThemeData theme) {
    if (cell.isRevealed) {
      return cell.isMine ? Colors.red.shade900 : theme.colorScheme.background;
    }
    return theme.primaryColor.withOpacity(0.3);
  }

  Widget _buildCellContent(Cell cell, ThemeData theme) {
    if (cell.isFlagged) {
      return const Icon(Icons.flag, color: Colors.white, size: 20);
    }
    if (cell.isRevealed) {
      if (cell.isMine) {
        return const Icon(Icons.new_releases, color: Colors.yellow, size: 24);
      }
      if (cell.adjacentMines > 0) {
        return Text(
          '${cell.adjacentMines}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _getMineCountColor(cell.adjacentMines),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Color _getMineCountColor(int count) {
    switch (count) {
      case 1:
        return Colors.blue.shade300;
      case 2:
        return Colors.green.shade300;
      case 3:
        return Colors.red.shade300;
      case 4:
        return Colors.purple.shade300;
      case 5:
        return Colors.orange.shade300;
      case 6:
        return Colors.teal.shade300;
      default:
        return Colors.pink.shade300;
    }
  }
}
