class String
  # Pre-formatted code blocks are used for writing about programming or markup
  # source code. Rather than forming normal paragraphs, the lines of a code
  # block are interpreted literally. Markdown wraps a code block in both <pre>
  # and <code> tags.
  #
  # To produce a code block in Markdown, simply indent every line of the block
  # by at least 4 spaces or 1 tab.
  MARKDOWN_CODEBLOCK = /^\ {4}|\t/

  # Match [[Page]] or even [[a page]] just like in wikipedia and gollum
  GIT_WIKI_SIMPLE_LINK = /\[\[([\w\s\+\-\.]+)\]\]/

  # Match [[Lone Star state|Texas]] just like gollum and unlike wikipedia
  # (wikipedia reverses the order of things)
  GIT_WIKI_COMPLEX_LINK = /\[\[([\w\s]+)\|([\w\s\+\-\.]+)\]\]/

  # Replace things that are obviously meant to be a url:
  #   http(s) or ftp or file then a colon and then some number of slashes,
  #   numbers, chars, question marks, dots (very important)...
  # It is far from perfect; it is good enough for now.
  GIT_WIKI_OBVIOUS_URI = /(https?|ftps?|file)\:[\/\\\w\d\/\-\+\?\!\&\=\.\_\@\%\&\*\~\#]+/

  def wiki_linked
    lines.map { |line| line.gsub_links }.join
  end

  def gsub_links
    return self if self =~ MARKDOWN_CODEBLOCK # ignore links in code blocks
    gsub_simple_links_with_markdown.gsub_complex_links_with_markdown
  end

  def gsub_simple_links_with_markdown
    gsub(GIT_WIKI_SIMPLE_LINK) do
      text = $1
      '[%s](/%s)' % [text, text.as_wiki_link]
    end
  end

  def gsub_complex_links_with_markdown
    gsub(GIT_WIKI_COMPLEX_LINK) do
      text, link = $1, $2
      '[%s](/%s)' % [text, link.as_wiki_link]
    end
  end

  def as_wiki_link
    gsub(/\+/, ' plus ').gsub(/\*/, ' times ').gsub(/\s/, '_')
  end
end


class Time
  def to_json
    (to_i * 1000).to_s
  end
end

