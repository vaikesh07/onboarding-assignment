# run.rb
#
# Description: The main execution script for the dice game.
#              It loads all necessary game components, prompts for player input,
#              and initiates the game.
#
# Author: Vaibhav
# Date: June 25, 2025
#
require './game'
include Game

print "Enter number of players: "
num_players = gets.chomp
game = GameClass.new(num_players.to_i)
game.play