# test/test_player.rb
require 'minitest/autorun'
require_relative '../player' # Adjust path
require_relative '../diceset' # Player depends on Dice
require_relative '../game_constants' # Player doesn't use constants directly, but it's good practice to ensure dependencies are loaded

include GameConstants

class TestPlayer < Minitest::Test
  include Player # Include the module to access PlayerClass
  include DiceSet # Include DiceSet for the Dice dependency

  def setup
    @mock_dice = Minitest::Mock.new # Use a mock object for Dice
    @player = PlayerClass.new(1, @mock_dice)
  end

  def test_initialize_player_name_and_score
    assert_equal "Player 1", @player.name, "Player name should be initialized correctly"
    assert_equal 0, @player.score, "Player score should be initialized to 0"
  end

  def test_play_rolls_dice
    # Expect the mock_dice to receive the :roll method with num_dice
    # and return a dummy array (the actual content doesn't matter for player.play)
    @mock_dice.expect(:roll, [1, 2, 3, 4, 5], [NUM_INITIAL_DICE_ROLL])

    @player.play(NUM_INITIAL_DICE_ROLL)

    # Verify that the expected method call happened on the mock
    @mock_dice.verify
  end

  def test_score_accessor
    @player.score = 150
    assert_equal 150, @player.score, "Score accessor should set and get score"
  end

  def test_eql_and_hash_methods
    player1 = PlayerClass.new(1, @mock_dice)
    player2 = PlayerClass.new(1, @mock_dice) # Same name
    player3 = PlayerClass.new(2, @mock_dice) # Different name

    assert player1.eql?(player2), "Players with same name should be equal"
    refute player1.eql?(player3), "Players with different names should not be equal"
    assert_equal player1.hash, player2.hash, "Players with same name should have same hash"
    refute_equal player1.hash, player3.hash, "Players with different names should have different hash (usually)"

    # Test usage as hash keys
    player_scores = { player1 => 100, player3 => 200 }
    assert_equal 100, player_scores[player2], "Hash lookup by equal player object should work"
  end
end
