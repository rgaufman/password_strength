# frozen_string_literal: true

require 'test_helper'

class TestMinLength < Minitest::Test
  def test_no_minimum_length_by_default
    strength = PasswordStrength.test('johndoe', '^P4ss$')

    refute_predicate strength, :too_short?
    assert_nil strength.invalid_reason
  end

  def test_reject_password_under_min_length
    strength = PasswordStrength.test('johndoe', '^P4ssw0rd$', min_length: 12)

    assert_predicate strength, :too_short?
    assert_equal :too_short, strength.invalid_reason
  end

  def test_a_short_password_is_invalid_at_every_level
    strength = PasswordStrength.test('johndoe', '^P4ssw0rd$', min_length: 12)

    refute strength.valid?(:weak)
    refute strength.valid?(:good)
    refute strength.valid?(:strong)
  end

  def test_accept_password_on_min_length
    strength = PasswordStrength.test('johndoe', '^P4ssw0rd12$', min_length: 12)

    refute_predicate strength, :too_short?
    assert_equal :strong, strength.status
  end

  def test_min_length_counts_characters_not_bytes
    strength = PasswordStrength.test('johndoe', 'çãéíóúàèìòù^1$', min_length: 12)

    refute_predicate strength, :too_short?
  end

  def test_windows2008_honours_min_length
    strength = PasswordStrength::Validators::Windows2008.new('johndoe', '^P4ssw0rd$', min_length: 12)
    strength.test

    assert_equal :too_short, strength.invalid_reason
  end
end
