# frozen_string_literal: true

require 'test_helper'

class TestActiveModelMinLength < Minitest::Test
  def setup
    PasswordStrength.enabled = true
    Object.class_eval { remove_const('User') } if defined?(User)
    load 'user.rb'
    @user = User.new
    I18n.locale = :en
  end

  def test_min_length_option
    User.validates_strength_of :password, min_length: 12

    @user.update_attributes password: '^P4ssw0rd$'

    assert_includes @user.errors.full_messages, 'Password is too short (minimum is 12 characters)'
  end

  def test_min_length_option_accepts_a_long_enough_password
    User.validates_strength_of :password, min_length: 12

    @user.update_attributes password: '^P4ssw0rd12$'

    assert_empty @user.errors.full_messages
  end

  def test_weak_password_still_reports_too_weak
    User.validates_strength_of :password, min_length: 12

    @user.update_attributes password: 'abcdefghijklm'

    assert_includes @user.errors.full_messages,
                    'Password is not secure; use letters (uppercase and downcase), numbers and special characters'
  end

  def test_invalid_min_length_option
    assert_raises(ArgumentError, 'The :min_length option must be a positive integer') do
      User.validates_strength_of :password, min_length: 0
    end
  end
end
