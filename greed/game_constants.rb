# game_constants.rb
# Description: Defines game-specific constants for points, thresholds,
#              and dice mechanics to improve maintainability and readability.


module GameConstants
    # --- Scoring Constants ---
    SCORE_ONE_SINGLE = 100
    SCORE_FIVE_SINGLE = 50
    SCORE_ONE_TRIPLE = 1000 # Three 1s
    SCORE_TRIPLE_MULTIPLIER = 100 # Multiplier for non-one triples (e.g., three 2s = 2 * 100)
  
    # --- Game Thresholds ---
    MIN_SCORE_TO_BANK = 300 # Minimum score required to bank points in a turn
    WINNING_SCORE = 3000    # Score required to trigger the final round
  
    # --- Dice Mechanics ---
    NUM_INITIAL_DICE_ROLL = 5 # Number of dice rolled at the start of a turn or hot dice
    NUM_DICE_SIDES = 6         # Standard six-sided die
    TRIPLE_COUNT = 3           # Number of dice required for a triple
  end
