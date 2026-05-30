# frozen_string_literal: true

require 'yaml'
require 'tmpdir'

module Hangman
  # Stores Hangman word dictionary
  class Database
    attr_reader :database

    def self.instance
      @database = []
      @instance ||= new
    end

    def load(filepath)
      @database = []
      File.open(filepath, 'r') do |file|
        until file.eof?
          word = file.readline.chomp
          @database.append(word) if word.size.between?(5, 12)
        end
      end
    end

    def sample
      @database.sample.upcase
    end
  end

  # Handles Hangman game state
  class State
    MAX_GUESSES = 6
    STATE_FILE_PREFIX = 'persistentgamestate_hangman_'
    SLOT = '_'
    ALLOWED = [' '].freeze
    BASE_DIR = Dir.tmpdir

    attr_accessor :word, :guesses
    attr_reader :filepath

    def initialize(word: Database.instance.sample, guesses: [], filepath: nil)
      @word = word
      @guesses = guesses
      @filepath = filepath
    end

    def self.list
      Dir.glob("#{STATE_FILE_PREFIX}*", base: BASE_DIR, sort: false).map { |f| self.load("#{BASE_DIR}/#{f}") }
    end

    def self.load(filepath)
      return unless File.exist?(filepath)

      state = Psych.load_file(filepath)
      return if state.nil?

      new(word: state[:word], guesses: state[:guesses], filepath: filepath)
    end

    def delete
      File.delete(@filepath) if @filepath
    end

    def save
      state = {
        word: @word,
        guesses: @guesses
      }
      @filepath = "#{BASE_DIR}/#{STATE_FILE_PREFIX}#{Time.now.to_i}" if @filepath.nil?
      File.write(@filepath, Psych.dump(state))
    end

    def parse_word(revail: false)
      (@word.chars.map do |e|
        next e if ALLOWED.include?(e)

        next (@guesses.include?(e) ? "\e[0;32m#{e}\e[0m" : "\e[0;34m#{e}\e[0m") if revail

        @guesses.include?(e) || ALLOWED.include?(e) ? e : SLOT
      end).join
    end

    def last_modified
      @filepath ? File.mtime(@filepath) : nil
    end

    def parse_guesses(revail: false)
      return [] if @guesses.empty?

      return @guesses unless revail

      @guesses.map { |e| @word.include?(e) ? "\e[0;32m#{e}\e[0m" : "\e[0;31m#{e}\e[0m" }
    end

    def found?
      @word.chars.none? { |e| !@guesses.include?(e) && !ALLOWED.include?(e) }
    end

    def errors
      @guesses.count { |e| !@word.include?(e) }
    end

    def chances_left
      MAX_GUESSES - errors
    end
  end

  # Handles Hangman game loop
  class Game
    PROMPT = '>>> '

    def run
      puts "*\e[33mHangman\e[0m*"

      loop do
        @state = prompt_menu
        @state.guesses.append(prompt_guess) until @state.found? || @state.chances_left.zero?

        puts(@state.found? ? 'Well done!' : 'Try harder next time!')
        display_hangman(revail: true)
        @state.delete
      end
    end

    private

    def list_game_states(states)
      states.each_with_index do |state, index|
        next if state.nil?

        puts "[#{index + 1}] #{state.last_modified}"
        puts "    Word: #{state.parse_word}"
        puts "    Guesses: #{state.parse_guesses.join(', ')}"
      end
      puts
    end

    def parse_menu_input(response, states)
      case response
      when 'e', 'exit' then exit
      when 'n', 'new' then State.new
      else
        n = response.to_i
        return unless n.between?(1, states.size)

        states[n - 1]
      end
    end

    def prompt_menu
      states = State.list
      list_game_states(states)

      puts "[N]ew Game\n[E]xit"
      loop do
        print PROMPT
        response = gets.strip.downcase
        parsed = parse_menu_input(response, states)
        break parsed unless parsed.nil?
      end
    end

    def handle_exit
      @state.save if loop do
        print 'Want to save the current state? [Y]es/[n]o '
        response = gets.chomp.downcase
        break %w[yes y].include?(response) if %w[yes y no n].include?(response)
      end
      exit
    end

    def prompt_guess
      display_game_header
      puts "Guess a letter or \e[0;31mexit\e[0;m"

      loop do
        print PROMPT
        prompt = gets.strip.upcase
        next handle_exit if prompt == 'EXIT'
        break prompt unless prompt.bytesize != 1 || @state.guesses.include?(prompt)
      end
    end

    # Poor man hangman
    def display_hangman(revail: false)
      errors = @state.errors
      puts  ' ┏━━┓  '
      puts  " ┃  #{errors.positive? ? '0' : ' '}  "
      print " ┃ #{errors > 2 ? '/' : ' '}#{errors > 1 ? '|' : ' '}#{errors > 3 ? '\\' : ' '} "
      puts @state.parse_word(revail: revail)
      puts  " ┃ #{errors > 4 ? '/' : ' '} #{errors > 5 ? '\\' : ' '} "
      puts  '━┻━    '
    end

    def display_game_header
      puts "\e[0;32m#{@state.chances_left}\e[0m chance#{'s' if @state.chances_left > 1} left!"
      puts "Guesses: #{@state.parse_guesses(revail: true).join(', ')}" unless @state.guesses.empty?
      display_hangman
    end
  end
end

if ARGV.length != 1
  puts 'Usage: ruby hangman.rb <word list file path>'
  exit
end

Hangman::Database.instance.load(ARGV.pop)
Hangman::Game.new.run
