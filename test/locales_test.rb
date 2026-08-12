# frozen_string_literal: true

require 'test_helper'

class TestLocales < Minitest::Test
  ENGLISH_TOO_WEAK = 'is not secure; use letters (uppercase and downcase), numbers and special characters'

  def setup
    @user = load_user_class
    User.validates_strength_of :password
  end

  def teardown
    I18n.locale = :en
  end

  def test_english_translates_too_weak
    I18n.locale = :en
    @user.update_attributes password: '123'

    assert_equal ENGLISH_TOO_WEAK, @user.errors.first.message
  end

  def test_every_shipped_locale_translates_too_weak
    shipped_locales.each do |locale|
      next if locale == 'en'

      I18n.locale = locale
      @user.update_attributes password: '123'

      refute_equal ENGLISH_TOO_WEAK, @user.errors.first.message, "#{locale} falls back to the English message"
    end
  end

  private

  def shipped_locales
    Dir[File.expand_path('../locales/*.yml', __dir__)].flat_map { |path| YAML.load_file(path, aliases: true).keys }
  end
end
