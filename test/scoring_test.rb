# frozen_string_literal: true

require 'test_helper'

class TestScoring < Minitest::Test
  def setup
    @strength = PasswordStrength::Base.new('johndoe', 'mypass')
  end

  def test_unknown_rule
    assert_raises(ArgumentError) { @strength.score_for(:whatever) }
  end

  def test_penalize_password_with_chars_only
    @strength.password = 'abcdef'

    assert_equal(-15, @strength.score_for(:only_chars))
  end

  def test_penalize_password_with_numbers_only
    @strength.password = '12345'

    assert_equal(-15, @strength.score_for(:only_numbers))
  end

  def test_penalize_password_equals_to_username
    @strength.username = 'johndoe'
    @strength.password = 'johndoe'

    assert_equal(-100, @strength.score_for(:username))
  end

  def test_penalize_password_with_username
    @strength.username = 'johndoe'
    @strength.password = '$1234johndoe^'

    assert_equal(-15, @strength.score_for(:username))
  end

  def test_penalize_number_sequence
    @strength.password = '234'

    assert_equal(-15, @strength.score_for(:sequences))

    @strength.password = '123123'

    assert_equal(-30, @strength.score_for(:sequences))
  end

  def test_penalize_letter_sequence
    @strength.password = 'abc'

    assert_equal(-15, @strength.score_for(:sequences))

    @strength.password = 'abcabc'

    assert_equal(-30, @strength.score_for(:sequences))
  end

  def test_penalize_number_and_letter_sequence
    @strength.password = '123abc'

    assert_equal(-30, @strength.score_for(:sequences))

    @strength.password = '123abc123abc'

    assert_equal(-60, @strength.score_for(:sequences))
  end

  def test_penalize_same_letter_sequence
    @strength.password = 'aaa'

    assert_equal(-30, @strength.score_for(:sequences))
  end

  def test_penalize_same_number_sequence
    @strength.password = '111'

    assert_equal(-30, @strength.score_for(:sequences))
  end

  def test_penalize_reversed_sequence
    @strength.password = 'cba321'

    assert_equal(-30, @strength.score_for(:sequences))

    @strength.password = 'cba321cba321'

    assert_equal(-60, @strength.score_for(:sequences))
  end

  def test_penalize_short_password
    @strength.password = 'abc'

    assert_equal(-100, @strength.score_for(:password_size))
  end

  def test_penalize_repetitions
    # 2-chars: ab, bc, cd, da           (4 * 4 = 16)
    # 3-chars: abc, bcd, cda, dab       (4 * 3 = 12)
    # 4-chars: abcd, bcda, cdab, dabc   (4 * 2 =  8)
    @strength.password = 'abcdabcdabcd'

    assert_equal(-36, @strength.score_for(:repetitions))
  end

  def test_password_length
    @strength.password = '123456'

    assert_equal 24, @strength.score_for(:password_size)
  end

  def test_password_with_numbers
    @strength.password = '123'

    assert_equal 5, @strength.score_for(:numbers)
  end

  def test_password_with_symbols
    @strength.password = '$!'

    assert_equal 5, @strength.score_for(:symbols)
  end

  def test_password_with_upper_and_lower_chars
    @strength.password = 'aA'

    assert_equal 10, @strength.score_for(:uppercase_lowercase)
  end

  def test_password_with_numbers_and_chars
    @strength.password = 'a1'

    assert_equal 15, @strength.score_for(:numbers_chars)
  end

  def test_password_with_numbers_and_symbols
    @strength.password = '1$'

    assert_equal 15, @strength.score_for(:numbers_symbols)
  end

  def test_password_with_symbols_and_chars
    @strength.password = 'a$'

    assert_equal 15, @strength.score_for(:symbols_chars)
  end
end
