#!/usr/bin/env ruby

require 'fileutils'
require './environment'
require 'sinatra'
require 'sinatra/content_for'

configure do
  set :erb, layout: :'layouts/defaults.slim'
  set :slim, layout: :'layouts/default'
end

helpers do
  def gravatar_url(email, size: 80)
    hash = Digest::MD5.hexdigest(email.to_s.strip.downcase)
    'http://www.gravatar.com/avatar/' + hash + "?s=#{size}&d=identicon"
  end
end
Dir["./app/helpers/*.rb"].each { |file| require file }
helpers PathHelpers

get('/') do
  @no_search_in_header = true
  @title = 'Git Wiki'
  slim :root
end

get '/a/history' do
  @history = $repo.log
  @title = "Branch History"
  slim :branch_history
end

# page paths

get '/:page' do
  @page = Page.new(params[:page])
  return redirect(edit_page_path(@page)) unless @page.tracked?
  @title = @page.nice_name
  slim :show
end

get '/:page/raw' do
  @page = Page.new(params[:page])
  send_data @page.raw_body, :type => 'text/plain', :disposition => 'inline'
end

get '/:page/edit' do
  @page = Page.new(params[:page])
  @title = "Editing #{@page.nice_name}"
  slim :edit
end

# post '/:page/append' do
#   @page = Page.new(params[:page])
#   @page.update(@page.raw_body + "\n\n" + params[:text], params[:message])
#   redirect '/' + @page.name
# end

post '/:page' do
  @page = Page.new(params[:page])
  @page.update(params[:body], params[:message])
  new_name = params[:name].gsub(/\s/, '_')
  if params[:page] == new_name
    redirect '/' + @page.name
  else
    $repo.lib.mv(params[:page], new_name)
    $repo.commit("Renamed #{params[:page]} to #{new_name}")
    redirect '/' + new_name
  end
end

post '/eip/:page' do
  @page = Page.new(params[:page])
  @page.update(params[:body])
  @page.body
end

get '/:page/history' do
  @page = Page.new(params[:page])
  @title = "History of #{@page.nice_name}"
  slim :page_history
end

get '/:page/history/:rev' do
  @page = Page.new(params[:page], params[:rev])
  @title = "#{@page.nice_name} (version #{params[:rev]})"
  slim :show
end

get '/d/:page/:rev' do
  @page = Page.new(params[:page])
  @title = "Diff of #{@page.name}"
  slim :delta
end

# application paths (/a/ namespace)

get '/a/list' do
  pages = $repo.log.first.gtree.children
  @pages = pages.select { |f,bl| f[0,1] != '_'}.sort.map { |name, blob| Page.new(name) } rescue []
  @title = 'All pages'
  slim :list
end

get '/a/patch/:page/:rev' do
  @page = Page.new(params[:page])
  header 'Content-Type' => 'text/x-diff'
  header 'Content-Disposition' => 'filename=patch.diff'
  @page.delta(params[:rev])
end

get '/a/tarball' do
  header 'Content-Type' => 'application/x-gzip'
  header 'Content-Disposition' => 'filename=archive.tgz'
  archive = $repo.archive('HEAD', nil, :format => 'tgz', :prefix => 'wiki/')
  File.open(archive).read
end

get '/a/branches' do
  @branches = $repo.branches
  @title = "Branches"
  slim :branches
end

get '/a/branch/:branch' do
  $repo.checkout(params[:branch])
  redirect '/' + HOMEPAGE
end


get '/a/revert_branch/:sha' do
  $repo.with_temp_index do
    $repo.read_tree params[:sha]
    $repo.checkout_index
    $repo.commit('reverted branch')
  end
  redirect '/a/history'
end

get '/a/merge_branch/:branch' do
  $repo.merge(params[:branch])
  redirect '/' + HOMEPAGE
end

get '/a/delete_branch/:branch' do
  $repo.branch(params[:branch]).delete
  redirect '/a/branches'
end

post '/a/new_branch' do
  $repo.branch(params[:branch]).create
  $repo.checkout(params[:branch])
  if params[:type] == 'blank'
    # clear out the branch
    $repo.chdir do
      Dir.glob("*").each do |f|
        File.unlink(f)
        $repo.remove(f)
      end
      touchfile
      $repo.commit('clean branch start')
    end
  end
  redirect '/a/branches'
end

post '/a/new_remote' do
  $repo.add_remote(params[:branch_name], params[:branch_url])
  $repo.fetch(params[:branch_name])
  redirect '/a/branches'
end

get '/a/search' do
  @q = Query.new($repo, params[:q])
  @perfect_match = @q.perfect_match
  @results = @q.results
  if @perfect_match
    @results.reject! { |result| result.filename == @perfect_match.filename }
  end
  slim :search
end

get '/a/git-wiki.css' do
  sass :'sass/git_wiki'
end

# file upload attachments
# get '/a/file/upload/:page' do
#   @page = Page.new(params[:page])
#   show :attach, 'Attach File for ' + @page.name
# end

# post '/a/file/upload/:page' do
#   @page = Page.new(params[:page])
#   @page.save_file(params[:file], params[:name])
#   redirect '/e/' + @page.name
# end

# get '/a/file/delete/:page/:file.:ext' do
#   @page = Page.new(params[:page])
#   @page.delete_file(params[:file] + '.' + params[:ext])
#   redirect '/e/' + @page.name
# end

# get '/_attachment/:page/:file.:ext' do
#   @page = Page.new(params[:page])
#   send_file(File.join(@page.attach_dir, params[:file] + '.' + params[:ext]))
# end

private

def show(template, title)
  @title = title
  erb(("#{template}.html").to_sym)
end

def touchfile
  # adds meta file to repo so we have somthing to commit initially
  $repo.chdir do
    f = File.new(".meta",  "w+")
    f.puts($repo.current_branch)
    f.close
    $repo.add('.meta')
  end
end

