require 'json'
require 'wordsearch/grid'

module WordSearch
  class Puzzle
    DIRS = {
      right:     [ 0,  1],
      left:      [ 0, -1],
      up:        [-1,  0],
      down:      [ 1,  0],
      rightdown: [ 1,  1],
      rightup:   [-1,  1],
      leftdown:  [ 1, -1],
      leftup:    [-1, -1]
    }

    attr_reader :vocabulary
    attr_reader :rows
    attr_reader :columns
    attr_reader :seed
    attr_reader :word_count
    attr_reader :word_rules

    attr_reader :unused_squares

    attr_reader :grid
    attr_reader :solution
    attr_reader :solution_dict
    attr_reader :grid_words

    def initialize(vocabulary, rows: 15, columns: 15, backward: false, seed: Time.now.to_i, word_count: 0, word_rules: nil)
      @vocabulary = vocabulary

      @rows = rows
      @columns = columns
      @backward = backward
      @seed = seed
      @solution_dict = {};
      @word_count = word_count;
      @word_rules = word_rules;
      @grid_words = [];

      srand(@seed)

      _generate!
    end

    def _generate!
      words = @vocabulary.dup
      max_length = [@columns, @rows].min
      words = words.select {|w| w.length <= max_length}
 
      if @backward
        directions = %i(left up)
        directions += %i(leftup leftdown)
      else
        directions = %i(right down)
        directions += %i(rightdown rightup)
      end

      grid = WordSearch::Grid.new(@rows, @columns)
      positions = (0...grid.size).to_a

      if !@word_rules.nil?
        @word_rules.each do |length, count|
          count = count.to_i

          words_list = words.select { |w| 
            w.length == length.to_i 
          }

          words -= words_list

          if words_list.size > 0
            _add_words(words_list, grid, directions, positions, count);
            @word_count -= count;
          end
        end
        if @word_count > 0
          _add_words(words, @grid, directions, positions);
        end
      elsif
        _add_words(words, grid, directions, positions);
      end

      @unused_squares = @grid.fill!()
    end

    def _add_words(words, grid, directions, positions, count = nil)
      count = @word_count if count.nil?;
      words = words.shuffle

      stack = [ { grid: grid, word: words.shift, dirs: directions.shuffle, positions: positions.shuffle } ]
      while true
        current = stack.last
        raise "no solution possible" if !current

        dir = current[:dirs].pop
        if dir.nil?
          current[:positions].pop
          current[:dirs] = directions.shuffle
          dir = current[:dirs].pop
        end

        pos = current[:positions].last

        if pos.nil?
          words.unshift(current[:word])
          stack.pop
        else
          grid = _try_word(current[:grid], current[:word], pos, dir)
          if grid
            @grid_words.push(current[:word])
            if words.any? && @grid_words.length < count
              words.shuffle;
              stack.push(grid: grid, word: words.shift, dirs: directions.shuffle,
                positions: positions.shuffle)
            else
              break # success!
            end
          end
        end
      end

      @grid = grid
      @solution = grid.dup
    end

    def _try_word(grid, word, position, direction)
      copy = grid.dup
      row, column = copy.at(position)

      dr, dc = DIRS[direction]
      letters = word.chars
      @solution_dict[word] = Array.new();

      while (row >= 0 && row < copy.rows) && (column >= 0 && column < copy.columns)
        letter = letters.shift || break

        if copy[row, column].nil? || copy[row, column] == letter
          copy[row, column] = letter
          @solution_dict[word].push([column, row])
          row += dr
          column += dc
        else
          return nil
        end
      end

      letters.any? ? nil : copy
    end

    def to_s(solution: false)
      s = ""

      @rows.times do |row|
        @columns.times do |col|
          s << " " if col > 0
          if solution
            s << (@solution[row, col] || ".")
          else
            s << @grid[row, col]
          end
        end
        s << "\n"
      end

      s
    end

    def to_json()
      grid = Array.new(@rows) { Array.new(@columns) }
      @rows.times do |row|
        @columns.times do |col|
          grid[row][col] = @grid[row, col]
        end
      end
      s = {:words => @grid_words.dup.to_a, :solution => @solution_dict, :grid => grid}
      s.to_json
    end
  end
end
