# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'

require 'minitest/autorun'
require 'minitest/utils'

require 'active_model'
require 'active_support/all'

I18n.enforce_available_locales = false
require 'password_strength'

module PasswordStrengthTestHelpers
  # A fresh User class per test, since each one declares its own validation.
  def load_user_class
    PasswordStrength.enabled = true
    Object.class_eval { remove_const('User') } if defined?(User)
    load 'user.rb'
    I18n.locale = :en

    User.new
  end
end

Minitest::Test.include(PasswordStrengthTestHelpers)
