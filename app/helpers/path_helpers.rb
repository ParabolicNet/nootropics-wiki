module PathHelpers
  def page_path(page)
    "/#{page.name}"
  end

  def edit_page_path(page)
    "/#{page.name}/edit"
  end

  def raw_page_path(page)
    "/#{page.name}/raw"
  end

  def page_history_path(page, revision = nil)
    revision = "/#{revision}" if revision
    "/#{page.name}/history" + revision.to_s
  end

  def page_history_diff_path(page, revision)
    "/#{page.name}/history/#{revision}/diff"
  end

  def page_history_patchfile_path(page, revision)
    "/#{page.name}/history/#{revision}.diff"
  end
end
