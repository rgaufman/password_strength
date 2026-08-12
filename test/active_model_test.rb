# frozen_string_literal: true

require 'test_helper'

class TestActiveModel < Minitest::Test
  def setup
    @user = load_user_class
  end

  def test_respond_to_validates_strength_of
    assert_respond_to User, :validates_strength_of
  end

  def test_error_messages_in_pt
    I18n.locale = 'pt-BR'
    User.validates_strength_of :password
    @user.update_attributes password: '123'

    assert_includes @user.errors.full_messages,
                    'Password não é segura; utilize letras (maiúsculas e mínusculas), números e caracteres especiais'
  end

  def test_error_messages_in_en
    I18n.locale = :en
    User.validates_strength_of :password
    @user.update_attributes password: '123'

    assert_includes @user.errors.full_messages,
                    'Password is not secure; use letters (uppercase and downcase), numbers and special characters'
  end

  def test_custom_error_message
    User.validates_strength_of :password, message: 'is too weak'
    @user.update_attributes password: '123'

    assert_includes @user.errors.full_messages, 'Password is too weak'
  end

  def test_defaults
    User.validates_strength_of :password

    @user.update_attributes username: 'johndoe', password: 'johndoe'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_strong_level
    User.validates_strength_of :password, level: :strong

    @user.update_attributes username: 'johndoe', password: '12345asdfg'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_weak_level
    User.validates_strength_of :password, level: :weak

    @user.update_attributes username: 'johndoe', password: 'johndoe'

    assert_empty @user.errors.full_messages
  end

  def test_lambda_strong_level
    User.validates_strength_of :password, level: ->(_u) { :strong }

    @user.update_attributes username: 'johndoe', password: '12345asdfg'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_lambda_weak_level
    User.validates_strength_of :password, level: ->(_u) { :weak }

    @user.update_attributes username: 'johndoe', password: 'johndoe'

    assert_empty @user.errors.full_messages
  end

  def test_lambda_with_string_return
    User.validates_strength_of :password, level: ->(_u) { 'weak' }

    @user.update_attributes username: 'johndoe', password: 'johndoe'

    assert_empty @user.errors.full_messages
  end

  def test_lambda_incorrect_level
    User.validates_strength_of :password, level: ->(_u) { 'incorrect_level' }

    assert_raises(ArgumentError, 'The :level option must be one of [:weak, :good, :strong], a proc or a lambda') do
      @user.update_attributes username: 'johndoe', password: 'johndoe'
    end
  end

  def test_custom_username
    User.validates_strength_of :password, with: :login

    @user.update_attributes login: 'johndoe', password: 'johndoe'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_blank_username
    User.validates_strength_of :password

    @user.update_attributes password: 'johndoe'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_exclude_option
    User.validates_strength_of :password, exclude: /\s/

    @user.update_attributes password: '^password with whitespaces 1234ASDF$'

    assert_predicate @user.errors.full_messages, :any?
  end

  def test_ignore_validations_when_password_strength_is_disabled
    User.validates_strength_of :password
    PasswordStrength.enabled = false
    @user.update_attributes password: ''

    assert_predicate @user, :valid?
  end

  # A tester that writes back to the record it was handed, to show that a
  # custom tester can reach it.
  RECORD_TESTER = Class.new(PasswordStrength::Base) do
    def test
      record.username = 'bar'
      good!
    end
  end

  def test_record_access_from_validator
    User.validates_strength_of :password, using: RECORD_TESTER
    @user.username = 'foo'
    @user.password = 'foo'
    @user.valid?

    assert_equal 'bar', @user.username
  end
end
