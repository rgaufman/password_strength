# frozen_string_literal: true

require_relative 'lib/password_strength/version'

Gem::Specification.new do |s|
  s.name                  = 'password_strength'
  s.version               = PasswordStrength::Version::STRING
  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 4.0'
  s.authors               = ['Nando Vieira']
  s.email                 = ['fnando.vieira@gmail.com']
  s.homepage              = 'https://github.com/rgaufman/password_strength'
  s.summary               = 'Check password strength against several rules. Includes ActiveRecord/ActiveModel support.'
  s.description           = s.summary
  s.license               = 'MIT'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/rgaufman/password_strength/issues',
    'source_code_uri' => 'https://github.com/rgaufman/password_strength',
    'rubygems_mfa_required' => 'true'
  }

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activemodel', '>= 6.0'
end
