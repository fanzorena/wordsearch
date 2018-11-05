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

    attr_reader :unused_squares

    attr_reader :grid
    attr_reader :solution
    attr_reader :solution_dict

    def initialize(vocabulary, rows: 15, columns: 15, diagonal: false, backward: false, message: nil, seed: Time.now.to_i)
      @vocabulary = vocabulary

      @rows = rows
      @columns = columns
      @diagonal = diagonal
      @backward = backward
      @message = message
      @seed = seed
      @solution_dict = {};

      srand(@seed)

      _generate!
    end

    def _generate!
      words = @vocabulary.dup

      directions = %i(right down)
      directions += %i(rightdown) if @diagonal
      directions += %i(left up) if @backward
      directions += %i(leftup leftdown rightup) if @diagonal && @backward

      grid = WordSearch::Grid.new(@rows, @columns)
      positions = (0...grid.size).to_a
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
            if words.any?
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

      @unused_squares = @grid.fill!(@message)
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
      words = @vocabulary.dup.to_a
      s = {:words => @vocabulary.dup.to_a, :solution => @solution_dict, :grid => grid}
      s.to_json
    end
  end
end
