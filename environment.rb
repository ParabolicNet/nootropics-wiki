require 'rubygems'
require 'bundler/setup'

require 'git'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'rubypants'

require './extensions'
require './page'


REPO_LOCATIONS = ["#{ENV['HOME']}/wiki", "#{ENV['HOME']}/.wiki"]

def is_repo?(location)
  File.exists?(location) && File.directory?(location)
end

def find_repo(locations = REPO_LOCATIONS)
  locations.detect do |location|
    is_repo?(location)
  end
end

def create_repo(location = REPO_LOCATIONS.first)
  puts "Initializing repository in #{location}..."
  Git.init(location)
  location
end

def find_or_create_repo
  find_repo || create_repo
end

GIT_REPO = find_or_create_repo
HOMEPAGE = 'home'

$repo = Git.open(GIT_REPO)



MARKDOWN_EXTENSIONS = {
  tables: true,
  fenced_code_blocks: true,
  space_after_headers: true,
  strikethrough: true,
  autolink: true }

class HTML < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet # hightlight code blocks with Rouge
end

$markdown = Redcarpet::Markdown.new(HTML, MARKDOWN_EXTENSIONS)
