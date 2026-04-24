# frozen_string_literal: true

# Mastermind game module
module Mastermind
  COLOR_CODES = { r: 31, g: 32, y: 33, b: 34, p: 35, c: 36 }.freeze
  COLOR_DESCRIPTIONS = { r: 'red', g: 'green', y: 'yellow', b: 'blue', p: 'purple', c: 'cyan' }.freeze
  COLOR_VALUES = COLOR_CODES.invert.freeze

  EMPTY = '○'
  FILLED = '●'
  SLOT = '·'
  PROMPT = '>>> '

  MIN_CODE_SIZE = 4
  MAX_CODE_SIZE = MIN_CODE_SIZE * 4
  MIN_GUESS_LIMIT = 8
  MAX_GUESS_LIMIT = MIN_GUESS_LIMIT * 4

  # Handles Mastermind board state
  class Board
    def initialize(code, guess_limit)
      @code = code.freeze
      @current_guess = 0
      @guess_limit = guess_limit
      @guesses = Array.new(@guess_limit, Array.new(@code.length, 0))
    end

    def display_content(show_code: false)
      stripes = '━' * @code.length
      puts "┏#{stripes}┳#{stripes}┓"
      puts "┃#{format_code(show_code)}┃#{'HINT'.center(@code.length)}┃"
      puts "┣#{stripes}╋#{stripes}┫"
      @guesses.reverse_each do |guess|
        puts "┃#{format_guess(guess)}┃#{format_hints(guess)}┃"
      end
      puts "┗#{stripes}┻#{stripes}┛"
    end

    def code_length
      @code.length
    end

    def format_code(show_code)
      return 'CODE'.center(@code.length) unless show_code

      format_pins(@code)
    end

    def format_guess(guess)
      return Array.new(@code.length, SLOT).join if guess.first.zero?

      format_pins(guess)
    end

    def format_pins(pins)
      pins.map { |pin| "\e[0;#{pin}m#{FILLED}\e[0m" }.join
    end

    def format_hints(guess)
      guess_hints(guess).join
    end

    def guess_hints(guess, code: @code.dup)
      ((0...guess.length).each_with_object([]) do |guess_index, hints|
        indices = code.each_index.select { |i| code[i] == guess[guess_index] }
        next hints.append(SLOT) if indices.empty?

        index = indices.include?(guess_index) ? guess_index : indices.first
        hints.append(index == guess_index ? FILLED : EMPTY)
        code[index] = 0
      end).sort.reverse
    end

    def winner?
      @current_guess != 0
      && (0...@code.length).reduce(true) { |match, i| match && last_guess[i] == @code[i] }
    end

    def out_of_guesses?
      @current_guess >= @guess_limit
    end

    def valid_code?(guess)
      guess.length == @code.length
      && guess.all?(COLOR_CODES.value?)
    end

    def guesses
      @guesses[0...@current_guess]
    end

    def last_guess
      @guesses[@current_guess - 1]
    end

    def place_guess(guess)
      @guesses[@current_guess] = guess
      @current_guess += 1
    end
  end

  # Handles Mastermind game loop
  class Game
    def run
      loop do
        puts "*\e[33mMastermind\e[0m*"
        case prompt_game_mode
        when 'maker', 'm' then run_maker_mode
        when 'breaker', 'b' then run_breaker_mode
        end

        break unless play_again?
      end
    end

    def prompt_game_mode
      loop do
        print 'Want to play as [B]reaker or [M]aker? '
        response = gets.chomp.downcase
        break response if %w[breaker b maker m].include?(response)
      end
    end

    def prompt_code_difficulty
      format_range = "[\e[0;32m#{MIN_CODE_SIZE}\e[0m(default)-\e[0;31m#{MAX_CODE_SIZE}\e[0m]"
      loop do
        print "How many colors the code can have? #{format_range} "
        code_size = gets.to_i
        code_size = MIN_CODE_SIZE if code_size.zero?
        break code_size if code_size.between?(MIN_CODE_SIZE, MAX_CODE_SIZE)
      end
    end

    def prompt_guesses_limit
      format_range = "[\e[0;32m#{MIN_GUESS_LIMIT}\e[0m(default)-\e[0;31m#{MAX_GUESS_LIMIT}\e[0m]"
      loop do
        print "How many guesses can be take? #{format_range} "
        guesses_limit = gets.to_i
        guesses_limit = MIN_GUESS_LIMIT if guesses_limit.zero?
        break guesses_limit if guesses_limit.between?(MIN_GUESS_LIMIT, MAX_GUESS_LIMIT)
      end
    end

    def run_breaker_mode
      @board = Board.new(pick_random_code(prompt_code_difficulty), prompt_guesses_limit)
      @board.place_guess(prompt_guess) until @board.out_of_guesses? || @board.winner?
      @board.display_content(show_code: true)
      puts(@board.winner? ? 'Code broken! Well done!' : 'Computer wins. Try harder next time!')
    end

    def run_maker_mode
      @board = Board.new(prompt_code, prompt_guesses_limit)
      @board.place_guess(pick_computed_guess) until @board.out_of_guesses? || @board.winner?
      @board.display_content(show_code: true)
      puts(@board.winner? ? 'Code broken! Try harder next time.' : 'Computer defeated. Well done!')
    end

    def play_again?
      loop do
        print 'Want to play again? [Y]es/[n]o '
        response = gets.chomp.downcase
        break %w[yes y].include?(response) if %w[yes y no n].include?(response)
      end
    end

    def display_help
      puts '# COLOR CODES'
      COLOR_CODES.each_pair { |k, v| puts "[\e[0;#{v}m#{k}\e[0m]: \e[0;#{v}m#{COLOR_DESCRIPTIONS[k]}\e[0m" }
      puts "Example -> #{pick_random_code.map { |pin| "\e[0;#{pin}m#{COLOR_VALUES[pin]}\e[0m" }.join}"
    end

    def convert_color_code(color_code)
      color_code.chars.map { |code| COLOR_CODES[code.to_sym] }
    end

    def pick_random_code(code_size = MIN_CODE_SIZE)
      values = COLOR_CODES.values
      (0...code_size).map { values.sample }
    end

    def pick_computed_guess
      pick_random_code(@board.code_length)
    end

    def prompt_guess
      @board.display_content
      puts "Type a sequence of \e[0;32m#{@board.code_length}\e[0m color codes.\nType ? to show available color codes."

      loop do
        print PROMPT
        input = gets.chomp
        next display_help if input == '?'

        guess = convert_color_code(input)
        break guess if @board.valid_code?(guess)
      end
    end

    def prompt_code
      display_help
      puts "Type a sequence of color codes between \e[0;32m#{MIN_CODE_SIZE}\e[0m and \e[0;31m#{MAX_CODE_SIZE}\e[0m."

      loop do
        print PROMPT
        code = convert_color_code(gets.chomp)
        break code if code.length.between?(MIN_CODE_SIZE, MAX_CODE_SIZE) && code.all? { |pin| COLOR_CODES.value? pin }
      end
    end
  end
end

Mastermind::Game.new.run
