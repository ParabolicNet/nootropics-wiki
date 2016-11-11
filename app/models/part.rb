class Part
  attr_accessor :source

  def initialize(source)
    @source = source
  end

  def self.parts(raw_body)
    parts = []
    paragraphs = raw_body.gsub("\r\n", "\n").split("\n\n")
    mode = nil
    paragraphs.each do |p|
      case mode
      when :append
        parts.last.source << "\n\n" << p
      else
        parts << Part.new(p)
      end
      mode = p.start_with?('#') ? :append : nil
    end
    parts
  end

  def to_html
    markdown = @source.wiki_linked
    html = $markdown.render(markdown)
    RubyPants.new(html).to_html
  end
end
