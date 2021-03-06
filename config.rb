###
# Blog settings
###

# Time.zone = "UTC"

activate :blog do |blog|
  # This will add a prefix to all links, template references and source paths
  # blog.prefix = "blog"

  blog.layout = "layouts/blog.erb"
  blog.permalink = "{title}.html"
  # Matcher for blog source files
  blog.sources = "articles/{year}-{month}-{day}-{title}.html"
  # blog.taglink = "tags/{tag}.html"
  # blog.layout = "layout"
  # blog.summary_separator = /(READMORE)/
  # blog.summary_length = 250
  # blog.year_link = "{year}.html"
  # blog.month_link = "{year}/{month}.html"
  # blog.day_link = "{year}/{month}/{day}.html"
  blog.default_extension = ".markdown"

  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"

  # Enable pagination
  blog.paginate = true
  blog.per_page = 10
  blog.page_link = "page/{num}"
end

activate :directory_indexes

page "/feed.xml", layout: false
#https://github.com/statonjr/middleman-sitemap
activate :sitemap, hostname: "https://kenlee.net"
# activate :youtube
###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", layout: false
#
# With alternative layout
# page "/path/to/file.html", layout: :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
activate :automatic_image_sizes

# Reload the browser automatically whenever files change
activate :livereload

activate :meta_tags

# Methods defined in the helpers block are available in templates
# helpers do
#   def set_meta_tag
#     "Helping"
#   end
# end


set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  activate :minify_html

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

# https://github.com/middleman-contrib/middleman-deploy
# activate :deploy do |deploy|
#   deploy.method = :git
#   # Optional Settings
#   deploy.remote   = 'https://github.com/geun/geun.github.io.git' # remote name or git url, default: origin
#   deploy.branch   = 'master' # default: gh-pages
#   # deploy.strategy = :submodule      # commit strategy: can be :force_push or :submodule, default: :force_push
#   # deploy.commit_message = 'custom-message'      # commit message (can be empty), default: Automated commit at `timestamp` by middleman-deploy `version`
#   deploy.build_before = true # default: false
# end

configure :development do |config|

  activate :disqus do |d|
    # using a special shortname
    d.shortname = "geunbaecomstaging"
    # or setting to `nil` will stop Disqus loading
    # d.shortname = nil
  end
end

configure :build do
  activate :disqus do |d|
    # using a different shortname for production builds
    d.shortname = "geunbae"
  end
end
