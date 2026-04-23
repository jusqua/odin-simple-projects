# frozen_string_literal: true

module TicTacToe
  BLANK = ' '
  NOUGHT = 'O'
  CROSS = 'X'
  MARKS = [NOUGHT, CROSS].freeze

  # Handles TicTacToe table state
  class Table
    def initialize(size = 3)
      @size = size
      @rooms = Array.new(size * size, BLANK)
    end

    def display_content(highlight: [], with_index: -1)
      last = @size - 1
      (0...@size).each do |row|
        (0...@size).each do |col|
          room = (row * @size) + col
          print format_room(room, highlight, with_index)
          print '┃' if col != last
        end
        puts "\n━#{'╋━' * last}" if row != last
      end
      puts
    end

    def format_room(room, highlight, with_index)
      format = if @rooms[room] != BLANK
                 "\e[34m#{@rooms[room]}\e[0m"
               elsif !with_index.negative?
                 "\e[32m#{String(room + with_index)}\e[0m"
               else
                 BLANK
               end
      format = format.gsub(/\e\[[0-9;?]*m/, '') unless highlight.include?(room)
      format
    end

    def available_rooms
      (0...(@size * @size)).each_with_object([]) do |index, rooms|
        rooms.append(index) if @rooms[index] == BLANK
      end
    end

    def no_rooms?
      @rooms.none? BLANK
    end

    def any_winner?
      column_winner_rooms.any?
      || row_winner_rooms.any?
      || back_diagonal_winner_rooms.any?
      || forward_diagonal_winner_rooms.any?
    end

    def winner_rooms
      rooms = column_winner_rooms
      rooms = row_winner_rooms if rooms.empty?
      rooms = back_diagonal_winner_rooms if rooms.empty?
      rooms = forward_diagonal_winner_rooms if rooms.empty?
      mark = rooms.first.nil? ? BLANK : @rooms[rooms.first]

      [mark, rooms]
    end

    def column_winner_rooms
      (0...@size).each_with_object([]) do |col, rooms|
        next rooms.clear if @rooms[col] == BLANK

        mark = @rooms[col]
        (0...@size).each do |row|
          room = (row * @size) + col
          rooms.append(room) if @rooms[room] == mark
        end

        break rooms if rooms.length == @size

        rooms.clear
      end
    end

    def row_winner_rooms
      (0...@size).each_with_object([]) do |row, rooms|
        next rooms.clear if @rooms[row * @size] == BLANK

        mark = @rooms[row * @size]
        (0...@size).each do |col|
          room = (row * @size) + col
          rooms.append(room) if @rooms[room] == mark
        end

        break rooms if rooms.length == @size

        rooms.clear
      end
    end

    def back_diagonal_winner_rooms
      return [] if @rooms.first == BLANK

      mark = @rooms.first
      (0...(@size * @size)).step(@size + 1).each_with_object([]) do |room, rooms|
        break [] if @rooms[room] != mark

        rooms.append(room)
      end
    end

    def forward_diagonal_winner_rooms
      return [] if @rooms[@size - 1] == BLANK

      mark = @rooms[@size - 1]
      ((@size - 1)...(@size * @size)).step(@size - 1).each_with_object([]) do |room, rooms|
        break [] if @rooms[room] != mark

        rooms.append(room)
      end
    end

    def can_place_mark?(room)
      room.between?(0, 8) && @rooms[room] == BLANK
    end

    def place_mark(room, mark)
      @rooms[room] = mark
    end
  end

  # Handles TicTacToe game loop
  class Game
    def initialize
      @mark = pick_random
    end

    def run
      loop do
        puts "*\e[33mTic Tac Toe\e[0m*"

        @table = Table.new
        until @table.no_rooms? || @table.any_winner?
          @table.place_mark(prompt_room, @mark)
          @mark = pick_next
        end

        show_results
        break unless play_again?
      end
    end

    def play_again?
      print 'Want to play again? [Y]es/[n]o '
      response = gets.chomp.downcase until %w[yes y no n].include?(response)
      %w[yes y].include?(response)
    end

    def show_results
      mark, rooms = @table.winner_rooms
      @table.display_content(highlight: rooms)
      if mark == BLANK
        puts "It's a tie!"
      else
        puts "#{mark} wins!"
      end
    end

    def prompt_room
      @table.display_content(highlight: @table.available_rooms, with_index: 1)
      puts "New turn! Mark your \e[34m#{@mark}\e[0m in any \e[32mNUMBERED ROOM\e[0m."

      room = -1
      until @table.can_place_mark? room
        print '>>> '
        room = gets.to_i - 1
      end
      room
    end

    def pick_random
      MARKS[Random.rand(MARKS.length)]
    end

    def pick_next
      MARKS[(MARKS.index(@mark) + 1) % MARKS.length]
    end
  end
end

TicTacToe::Game.new.run
