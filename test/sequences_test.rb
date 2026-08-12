# frozen_string_literal: true

require 'test_helper'

class TestSequences < Minitest::Test
  def setup
    @strength = PasswordStrength::Base.new('johndoe', 'mypass')
  end

  def test_two_chars_repetition
    # expected: 11, 22, 12
    assert_equal 3, @strength.repetitions('11221122', 2)
  end

  def test_three_chars_repetition
    # expected: 123, 231, 312
    assert_equal 3, @strength.repetitions('123123123', 3)
  end

  def test_four_chars_repetition
    # expected: abcd, bcda, cdab, dabc
    assert_equal 4, @strength.repetitions('abcdabcdabcd', 4)
  end

  def test_special_chars_repetition
    # expected: §§, ££, §£
    assert_equal 3, @strength.repetitions('§§££§§££', 2)

    # expected: §£€, £€§, €§£
    assert_equal 3, @strength.repetitions('§£€§£€§£€', 3)

    # expected: §£€à, £€à§, €à§£, à§£€
    assert_equal 4, @strength.repetitions('§£€à§£€à§£€à', 4)
  end

  def test_counts_a_run_of_three
    assert_equal 1, @strength.sequences('abc')
  end

  def test_counts_a_run_of_the_same_character
    assert_equal 1, @strength.sequences('aaa')
  end

  def test_sequences_count_characters_not_bytes
    assert_equal 0, @strength.sequences('çãé')
  end
end
