# diceset.rb
#
# Description: Defines the DiceSet module and the Dice class,
#              which manages the rolling and representation of dice in the game.



module DiceSet
    class Dice
      attr_reader :values
   
      def initialize
        @values = []
      end
  
     def to_s
       st = ""
       @values.each { |x| 
         st += "#{x}, "
       }
       st = st.chomp(", ")
     end
  
      def roll(n)
        @values = []
        n.times { @values << rand(1..6) }
      end
    end
  end
