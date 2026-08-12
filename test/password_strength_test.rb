# frozen_string_literal: true

require 'test_helper'

class TestPasswordStrength < Minitest::Test
  def setup
    @strength = PasswordStrength::Base.new('johndoe', 'mypass')
    @password_limit = PasswordStrength::Base.const_get(:PASSWORD_LIMIT)
    @username_limit = PasswordStrength::Base.const_get(:USERNAME_LIMIT)
  end

  def teardown
    set_const(:PASSWORD_LIMIT, @password_limit)
    set_const(:USERNAME_LIMIT, @username_limit)
  end

  def test_shortcut
    @strength = PasswordStrength.test('johndoe', 'mypass')

    assert_kind_of PasswordStrength::Base, @strength
    assert_equal 'johndoe', @strength.username
    assert_equal 'mypass', @strength.password
  end

  def test_deal_with_empty_password
    @strength = PasswordStrength.test('johndoe', '')

    assert_predicate @strength, :weak?
  end

  def test_short_password
    @strength.password = 'xyz'
    @strength.test

    assert_equal 0, @strength.score
    assert_equal :weak, @strength.status
  end

  def test_password_equals_to_username
    @strength.password = 'johndoe'
    @strength.test

    assert_equal 0, @strength.score
    assert_equal :weak, @strength.status
  end

  def test_strong_password
    @strength.password = '^P4ssw0rd$'
    @strength.test

    assert_equal 100, @strength.score
    assert_equal :strong, @strength.status
  end

  def test_weak_password
    @strength.password = 'ytrewq'
    @strength.test

    assert_equal :weak, @strength.status

    @strength.password = 'asdfghjklm'
    @strength.test

    assert_equal :weak, @strength.status
  end

  def test_good_password
    @strength.password = '12345asdfg'
    @strength.test

    assert_equal :good, @strength.status

    @strength.password = '12345ASDFG'
    @strength.test

    assert_equal :good, @strength.status

    @strength.password = '12345Aa'
    @strength.test

    assert_equal :good, @strength.status
  end

  def test_reject_long_passwords_using_same_character
    @strength = PasswordStrength.test('johndoe', 'a' * 50)

    assert_predicate @strength, :invalid?
    assert_equal :repeated_character, @strength.invalid_reason
  end

  def test_exclude_option_as_regular_expression
    @strength = PasswordStrength.test('johndoe', '^Str0ng P4ssw0rd$', exclude: /\s/)

    assert_predicate @strength, :invalid?
    assert_equal :excluded_characters, @strength.invalid_reason
  end

  def test_exclude_option_as_array
    @strength = PasswordStrength.test('johndoe', 'asdfasdfasdf', exclude: %w[asdf 123])

    assert_predicate @strength, :invalid?
    assert_equal :excluded_characters, @strength.invalid_reason
  end

  def test_long_passwords_same_as_truncated
    set_const(:PASSWORD_LIMIT, 20)

    assert_equal(*[('ab' * 10), ('ab' * 100)].map { |password| result_for('johndoe', password) })
  end

  def test_long_usernames_same_as_truncated
    set_const(:USERNAME_LIMIT, 20)

    assert_equal(*[('ab' * 10), ('ab' * 100)].map { |username| result_for(username, '^Str0ng P4ssw0rd$') })
  end

  def set_const(const, value)
    PasswordStrength::Base.send(:remove_const, const)
    PasswordStrength::Base.const_set(const, value)
  end

  private

  # Everything the caller can read back from a test, so two runs can be
  # compared in one assertion.
  def result_for(username, password)
    strength = PasswordStrength.test(username, password)

    [strength.score, strength.password, strength.username, strength.status]
  end
end
