# frozen_string_literal: true

require 'test_helper'

class Window2008Test < Minitest::Test
  def setup
    PasswordStrength.enabled = true
    Object.class_eval { remove_const('User') } if defined?(User)
    load 'user.rb'
    User.validates_strength_of :password, using: PasswordStrength::Validators::Windows2008

    @user = User.new(username: 'Administrator')
  end

  # Every pair of the four categories, none of which reaches the three
  # categories Windows 2008 asks for.
  TWO_CATEGORY_PASSWORDS = %w[abcABC abc123 abc$!~ 123ABC 123$!~ ABC$!~].freeze

  def test_require_password_to_include_three_character_categories
    rejected = TWO_CATEGORY_PASSWORDS.reject do |password|
      @user.update_attributes(password: password).errors.full_messages.any?
    end

    assert_empty rejected, "these passwords were accepted with two character categories: #{rejected.join(', ')}"
  end

  def test_invalidate_password_that_includes_username
    @user.update_attributes password: 'abc$!~ABC123Admin'

    assert_predicate @user.errors.full_messages, :any?

    @user.update_attributes password: 'abc$!~ABC123Adm'

    assert_predicate @user.errors.full_messages, :any?

    @user.update_attributes password: 'abc$!~ABC123admin'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_invalidate_short_passwords
    @user.update_attributes password: '12345'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_accept_numbers_uppercases_and_lowercases
    @user.update_attributes password: '123ABCabc'

    assert_predicate @user, :valid?
  end

  def test_accept_numbers_uppercases_and_special_chars
    @user.update_attributes password: '123ABC$!~'

    assert_predicate @user, :valid?
  end

  def test_accept_numbers_lowercases_and_special_chars
    @user.update_attributes password: '123ABC$!~'

    assert_predicate @user, :valid?
  end

  def test_accept_uppercases_lowercases_and_special_chars
    @user.update_attributes password: 'ABCabc$!~'

    assert_predicate @user, :valid?
  end
end
