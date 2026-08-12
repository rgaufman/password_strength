# frozen_string_literal: true

require 'test_helper'

class TestStatus < Minitest::Test
  def setup
    @strength = PasswordStrength::Base.new('johndoe', 'mypass')
  end

  def test_good_strength
    @strength.good!

    assert_predicate @strength, :good?
    assert @strength.valid?(:good)
    refute_predicate @strength, :weak?
    refute_predicate @strength, :strong?
  end

  def test_weak_strength
    @strength.weak!

    assert_predicate @strength, :weak?
    assert @strength.valid?(:weak)
    refute_predicate @strength, :good?
    refute_predicate @strength, :strong?
  end

  def test_strong_strength
    @strength.strong!

    assert_predicate @strength, :strong?
    assert @strength.valid?(:strong)
    assert @strength.valid?(:good)
    refute_predicate @strength, :good?
    refute_predicate @strength, :weak?
  end

  def test_invalid_strength
    @strength.invalid!(:common_word)

    assert_predicate @strength, :invalid?
    assert_equal :common_word, @strength.invalid_reason
    refute @strength.valid?(:weak)
  end

  def test_invalid_without_a_reason
    @strength.invalid!

    assert_predicate @strength, :invalid?
    assert_nil @strength.invalid_reason
  end
end
