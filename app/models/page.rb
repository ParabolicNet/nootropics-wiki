require_relative 'attachment'
require_relative 'part'

class Page
  attr_reader :name
  # ATTACHMENTS_DIR = '_attachments'

  def initialize(name, rev = nil)
    @name = name
    @rev = rev
  end

  def to_s
    @name
  end

  def nice_name
    name.gsub('_', ' ')
  end

  def path
    @path ||= File.join(GIT_REPO, @name)
  end

  # def attach_dir
  #   @attach_dir ||= File.join(GIT_REPO, ATTACHMENTS_DIR, @name.downcase)
  # end

  def body
    @body ||= render_body(raw_body)
  end

  def toc
    @toc ||=  render_toc(raw_body)
  end

  def to_html
    toc + body
  end


  def source
    raw_body
  end

  def parts
    Part.parts(raw_body)
  end

  def first_paragraph
    p = raw_body.gsub("\r\n", "\n").split("\n\n").first
    render_body p
  end

  def render_body(source)
    markdown = source.wiki_linked
    html = $markdown.render(markdown)
    RubyPants.new(html).to_html
  end

  def render_toc(source)
    markdown = source.wiki_linked
    toc = $markdown_toc.render(markdown)
    return '' if toc.lines.count { |line| line.include? '<li>' } < 2
    "<div class='toc'><h1 class='toc__title'>Contents</h1>#{toc}</div>"
  end

  def branch_name
    $repo.current_branch
  end

  def updated_at
    commit.committer_date
  end

  def raw_body
    if @rev
      @raw_body ||= blob.contents
    else
      @raw_body ||= File.exists?(path) ? File.read(path) : ''
    end
  end

  def update(content, message = nil)
    File.open(path, 'w') { |f| f << content }
    commit_message = tracked? ? "Edit #{@name}" : "Create #{@name}"
    commit_message += ' : ' + message if message && message.length > 0
    begin
      $repo.add(@name)
      $repo.commit(commit_message)
    rescue
      # FIXME I don't like this, why is there a catchall here?
      nil
    end
    @body = nil; @raw_body = nil
    @body
  end

  def tracked?
    $repo.ls_files.keys.include?(@name)
  end

  def history
    return nil unless tracked?
    @history ||= $repo.log.path(@name)
  end

  def delta(rev)
    $repo.diff(previous_commit, rev).path(@name).patch
  end

  def commit
    @commit ||= $repo.log.object(@rev || 'master').path(@name).first
  end

  def previous_commit
    @previous_commit ||= $repo.log(2).object(@rev || 'master').path(@name).to_a[1]
  end

  def next_commit
    if (self.history.first.sha == self.commit.sha)
      @next_commit ||= nil
    else
      matching_index = nil
      history.each_with_index { |c, i| matching_index = i if c.sha == self.commit.sha }
      @next_commit ||= history.to_a[matching_index - 1]
    end
  rescue
    # FIXME weird catch-all error handling
    @next_commit ||= nil
  end

  def version(rev)
    data = blob.contents
    render_body(data)
    # RubyPants.new(Redcarpet::Markdown.new(data.wiki_linked).to_html).to_html
  end

  def blob
    @blob ||= ($repo.gblob(@rev + ':' + @name))
  end

  # save a file into the _attachments directory
  def save_file(file, name = '')
    if name.size > 0
      filename = name + File.extname(file[:filename])
    else
      filename = file[:filename]
    end
    FileUtils.mkdir_p(attach_dir) if !File.exists?(attach_dir)
    new_file = File.join(attach_dir, filename)

    f = File.new(new_file, 'w')
    f.write(file[:tempfile].read)
    f.close

    commit_message = "uploaded #{filename} for #{@name}"
    begin
      $repo.add(new_file)
      $repo.commit(commit_message)
    rescue
      # FIXME why!??
      nil
    end
  end

  def delete_file(file)
    file_path = File.join(attach_dir, file)
    if File.exists?(file_path)
      File.unlink(file_path)

      commit_message = "removed #{file} for #{@name}"
      begin
        $repo.remove(file_path)
        $repo.commit(commit_message)
      rescue
        # FIXME why is this here!?
        nil
      end

    end
  end

  # def attachments
  #   if File.exists?(attach_dir)
  #     return Dir.glob(File.join(attach_dir, '*')).map { |f| Attachment.new(f, unwiki(@name)) }
  #   else
  #     false
  #   end
  # end
end

