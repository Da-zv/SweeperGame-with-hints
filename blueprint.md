# Sweeper

## Overview

A classic Minesweeper game with user interface and an AI-powered hint feature. 
The AI hint feature uses Groq API with qwen/qwen3-32b model to suggest the next best move.

## Style, Design, and Features

### Implemented

*   **Core Gameplay:** Classic Minesweeper logic with a grid of cells, mines, and number clues.
*   **Game State:** The app tracks game over and game won states.
*   **Timer:** A stopwatch to time the game.
*   **UI:**
    *   interface with a dark and light theme.
    *   Uses `google_fonts` for a retro, pixelated aesthetic.
    *   A settings dialog to customize the board size and number of mines.
    *   A theme toggle to switch between light and dark mode.
*   **AI Hints:**
    *   A button to request a hint from a AI model.
    *   The AI is provided with the current board state and asked for a safe move.
    *   The hint is displayed in a alert dialog.

### Current Plan

The project is complete. The application is fully functional with a UI and AI-powered hints.
But could use some prompt engineering to make AI models more reliable.
