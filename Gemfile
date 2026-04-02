# frozen_string_literal: true
# encoding: utf-8

source "https://rubygems.org"

gemspec

gem "html-proofer", "~> 5.0", group: :test

platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.2.0", :platforms => [:windows]

# Trying to get last modified
group :jekyll_plugins do
  gem "jekyll-last-modified-at"
end
