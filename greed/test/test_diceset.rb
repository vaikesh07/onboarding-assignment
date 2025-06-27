# test/test_diceset.rb
require 'minitest/autorun'
require_relative '../diceset' # Adjust path if your structure is different
require_relative '../game_constants' # If Dice needs constants in the future, include it. For now, it doesn't directly.

include GameConstants

class TestDice < Minitest::Test
  include DiceSet # Include the module to access Dice class directly

  def setup
    @dice = Dice.new
  end

  def test_initialize_empty_values
    assert_empty @dice.values, "Dice values should be empty on initialization"
  end

  def test_roll_populates_values
    @dice.roll(NUM_INITIAL_DICE_ROLL)
    assert_equal NUM_INITIAL_DICE_ROLL, @dice.values.length, "Rolled dice should have the correct number of values"
    @dice.values.each do |value|
      assert_includes 1..6, value, "Each rolled value should be between 1 and 6"
    end
  end

  def test_roll_clears_previous_values
    @dice.roll(2)
    refute_empty @dice.values, "Values should not be empty after first roll"
    @dice.roll(4)
    assert_equal 4, @dice.values.length, "New roll should overwrite previous values"
  end

  def test_to_s_representation
    # Temporarily set values for testing to_s
    @dice.instance_variable_set(:@values, [1, 2, 3])
    assert_equal "1, 2, 3", @dice.to_s, "to_s should format values correctly"

    @dice.instance_variable_set(:@values, [5])
    assert_equal "5", @dice.to_s, "to_s should handle single value correctly"

    @dice.instance_variable_set(:@values, [])
    assert_equal "", @dice.to_s, "to_s should handle empty values correctly"
  end
end
