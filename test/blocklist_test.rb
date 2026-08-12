# frozen_string_literal: true

require 'test_helper'

class TestBlocklist < Minitest::Test
  def teardown
    PasswordStrength::Base.blocklist = nil
  end

  def test_loads_common_words
    assert_operator PasswordStrength::Base.common_words.size, :>, 500
  end

  def test_reject_common_words
    password = PasswordStrength::Base.common_words.first
    strength = PasswordStrength.test('johndoe', password)

    assert_predicate strength, :invalid?, "#{password} must be invalid"
    refute_predicate strength, :valid?
  end

  def test_invalid_reason_for_common_word
    strength = PasswordStrength.test('johndoe', 'password')

    assert_equal :common_word, strength.invalid_reason
  end

  def test_reject_common_word_written_in_leet
    strength = PasswordStrength.test('johndoe', 'P@ssw0rd')

    assert_equal :common_word, strength.invalid_reason
  end

  # Digits fold as well as symbols do: a class built with a backslash in front
  # of a digit reads as an octal escape and silently stops matching it.
  def test_reject_common_word_written_with_digits_for_letters
    strength = PasswordStrength.test('johndoe', 'l3tm31n')

    assert_equal :common_word, strength.invalid_reason
  end

  def test_reject_common_word_followed_by_digits
    strength = PasswordStrength.test('johndoe', 'monkey2024')

    assert_equal :common_word, strength.invalid_reason
  end

  def test_accept_passphrase_that_only_contains_a_common_word
    strength = PasswordStrength.test('johndoe', 'blue-River-42-lamp')

    assert_predicate strength, :valid?
  end

  def test_custom_blocklist_rejects_its_own_words
    PasswordStrength::Base.blocklist = %w[TetherX]
    strength = PasswordStrength.test('johndoe', 'T3therX99')

    assert_equal :common_word, strength.invalid_reason
  end

  def test_custom_blocklist_replaces_the_bundled_list
    PasswordStrength::Base.blocklist = %w[TetherX]
    strength = PasswordStrength.test('johndoe', 'password')

    refute_predicate strength, :invalid?
  end

  def test_a_subclass_shares_the_list
    PasswordStrength::Base.blocklist = %w[TetherX]

    assert_includes PasswordStrength::Validators::Windows2008.blocklist_set, 'tetherx'
  end
end
