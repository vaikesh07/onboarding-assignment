# player.rb
#
# Description: Defines the Player module and the PlayerClass,
#              representing individual players in the game, managing their name, score,
#              and interaction with the dice.
#
module Player
    class PlayerClass
      attr_reader :name
      attr_accessor :score
  
      def initialize(i,dice)
        @name = "Player "+i.to_s
        @dice = dice
        @score = 0
      end
  
      def play(num_dice)
        values = @dice.roll(num_dice)
      end
  
      def eql?(other_ob)
        @name == other_ob.name
      end
  
      def hash
        @name.hash
      end
  
    end
  end  
          