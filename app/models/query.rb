require 'forwardable'
require_relative 'search_result'

class Query
  extend Forwardable
  attr_reader :query, :words
  def_delegator :@query, :to_s

  def initialize(repository, q)
    @repo = repository
    @query = q.to_s
    @words ||= @query.split(' ')
    @subqueries = subqueries
    @score = words.size
  end

  def subqueries
    return [] if @words.size <= 1
    @words.map { |word| self.class.new(@repo, word) }
  end

  def results
    [search_on_filename, git_grep, @subqueries.map(&:results)]
      .flatten
      .group_by(&:filename)
      .map { |_filename, results| SearchResult.merger(results) }
      .sort
  end

  # find a page with the exact same name as query
  def perfect_match
    query = @query.downcase.as_wiki_link
    page = all_pages.detect { |name| name.downcase == query }
    SearchResult.new(page, 1) if page
  end

  # find pages where a part of the title matches the query
  def search_on_filename
    needle = query.downcase.as_wiki_link
    all_pages.select { |name| name.downcase.include? needle }.map do |name|
      # unfreeze the String name by creating a "new" one
      SearchResult.new(name, 2  * @score, [0, name.tr('_', ' ')])
    end
  end

  # grep returns a hash:
  #   [tree-ish] => [[line_no, match], [line_no, match2]]
  #   [tree-ish] => [[line_no, match], [line_no, match2]]
  def git_grep
    # grep on the root object implies searching on HEAD
    grep = @repo.grep(query, nil, ignore_case: true)
    grep.map do |treeish, matches|
      _sha, filename = treeish.split(':', 2)
      SearchResult.new(filename, @score, *matches)
    end.sort
  end

  def to_regexp
    terms = [@query, @words].flatten.sort_by(&:length).reverse.uniq
    regexps = terms.map do |term|
      Regexp.new(Regexp.escape(term), Regexp::EXTENDED | Regexp::IGNORECASE)
    end
    Regexp.union(*regexps)
  end

  private

  def all_pages
    @repo.log.first.gtree.children.keys
  end
end

