# game.rb
#
# Description: Defines the main Game module and GameClass,
#              orchestrating the entire game flow, including managing players,
#              scoring logic, turn mechanics, and determining the winner.
#              This file contains the core rules of the dice game (similar to Farkle/Greed).
require './player'
include Player

require './diceset'
include DiceSet

module Game
  class GameClass
  
    def initialize(num_players)
      raise ArgumentError unless num_players > 1
      @players = []
      @player_score = {}
      @dice = Dice.new
      count = 1
      num_players.times { 
        p = PlayerClass.new(count,@dice)
        @players << p
        @player_score[p] = 0
        count += 1
      }
    end

    def score
      v = @dice.values
      v.sort!
      current_score = 0
      i = 0
      while i < v.length
        if v[i] == v[i+1] && v[i+1] == v[i+2]
          if v[i] == 1
            current_score += 1000
          else
            current_score += (v[i]*100)
          end
          i += 3
        else
          if v[i] == 1
            current_score += 100
          elsif v[i] == 5
            current_score += 50
          end
          i += 1
        end
      end
      current_score
    end

    def take_input_to_play_again(player,cur_num)
      print "Do you want to roll the non-scoring #{cur_num} dice? (y/n): "
      choice = gets.chomp.downcase
    end

    def get_nonscoring_num
      count = 0
      repeated = []
      v = @dice.values.sort
      i = 0
      while i < v.length
        if v[i] == v[i+1] && v[i+1] == v[i+2]
          i += 3
        elsif (v[i] != 1  && v[i] != 5)
          i += 1
          count += 1
        else
          i += 1
        end
      end
      count = 5 if count == 0
      count
    end

    def play_turn(player)
      player.play(5)
      sleep 1 # slow down a bit so that user can see what's happening
      cur_score = score
      print "#{player.name} rolls: " + @dice.to_s+"\n"
      print "Score in this round: #{score} \n"
      print "Total score: #{@player_score[player]}\n"
      if cur_score != 0
        loop do
          n = get_nonscoring_num
          choice = take_input_to_play_again(player,n)
          if choice == 'y'
            player.play(n)
            print "#{player.name} rolls: " + @dice.to_s + "\n"
            new_score = score
            if new_score == 0
              cur_score = 0
              print "Score in this round: #{new_score} \n"
              print "Total score: #{@player_score[player]}\n"
              break
            end
            cur_score += new_score
            print "Score in this round: #{new_score} \n"
            print "Total score: #{@player_score[player]}\n"
          else  # Anything else resorts to No
            if (@player_score[player] >= 300 || cur_score >=300) 
              @player_score[player] += cur_score
            end
            break
          end
        end
      end
    end        
    
    def final_round?
      @player_score.each_value { |x| 
        return true if x >= 3000
      }
      return false
    end

    def get_winner
      m = -1
      winner = nil
      @player_score.each { |k,v| 
        if m < v
          m = v
          winner = k
        end
      }
      winner
    end

    def print_scores
       print "############################################################\n"
       @player_score.each { |k,v|
         puts "#{k.name}'s score at the end of this round is .. #{v}"
       }
       print "############################################################\n"
    end

    def play
      turn = 1
      loop do
        print "Turn #{turn}\n"
        print "------------\n"
        @players.each { |x|
          play_turn(x)
          print "\n"
        }
        turn += 1
        break if final_round? 
      end
      # get one more turn for others & compute final score
      print "Final round\n"
      print "-----------\n"
      @players. each { |x|
        if @player_score[x] < 3000
          play_turn(x)
        end
      }
      winner = get_winner
      print "winner is #{winner.name} .. score is " + @player_score[winner].to_s + "\n"
    end
  end
end       
