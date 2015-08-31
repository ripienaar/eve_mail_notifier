# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','emn/version.rb'])

spec = Gem::Specification.new do |s|
  s.name = 'emn'
  s.version = EMN::VERSION
  s.author = 'R.I.Pienaar'
  s.email = 'rip@devco.net'
  s.homepage = 'https://github.com/ripienaar/eve_mail_notifier'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Eve Online New Mail Notifier'
  s.description = "Get Pushover notification when your characters get mail"
# Add your other files here if you make them
  s.files = Dir.glob("{README.md,COPYING,bin,lib,templates}/**/*").to_a
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.bindir = 'bin'
  s.executables << 'emn'
  s.add_dependency 'eaal'
  s.add_dependency 'pushover'
  s.add_dependency 'tilt'
end
