require 'forwardable'

class SearchResult
  extend Forwardable
  attr_reader :filename
  attr_accessor :score
  def_delegator :@matches, :<<

  def initialize(filename, score, *match)
    @filename = filename
    @score = score.to_i
    @matches = Array(match)
  end

  def self.merger(results)
    new(results.first.filename, results.map(&:score).sum, *results.flat_map(&:matches).uniq)
  end

  def to_s
    filename.tr('_', ' ')
  end

  def matches
    @matches.sort
  end

  def to_sort_values
    [-score, @filename]
  end

  def <=>(other)
    to_sort_values <=> other.to_sort_values
  end

  def to_page
    Page.new(@filename)
  end
end
