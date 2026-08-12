# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'

require 'minitest/autorun'
require 'minitest/utils'

require 'active_model'
require 'active_support/all'

I18n.enforce_available_locales = false
require 'password_strength'
