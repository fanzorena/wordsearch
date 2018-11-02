lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "wordsearch/version"

Gem::Specification.new do |gem|
  gem.version     = WordSearch::Version::STRING
  gem.name        = "wordsearch-puzzle"
  gem.authors     = ["Fabricio Anzorena"]
  gem.email       = ["fabricio@cupcakese.com"]
  gem.homepage    = "http://github.com/fanzorena/wordsearch"
  gem.summary     = "A word-search puzzle generator, utility and library. Fork from Jamis Buck generator (https://github.com/jamis/wordsearch)"
  gem.description = %q{Generates word-search puzzles and emits them to PDF. Customizable.}
  gem.license     = 'CC-BY-4.0'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = "wordsearch"
  gem.require_paths = ["lib"]
end
