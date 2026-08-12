# frozen_string_literal: true

require 'password_strength/blocklist'
require 'password_strength/scoring'
require 'password_strength/status'

module PasswordStrength
  # Score a password against the rules in PasswordStrength::Scoring and the
  # list in PasswordStrength::Blocklist, and report the result as a status of
  # :invalid, :weak, :good or :strong.
  class Base
    include Blocklist
    include Scoring
    include Status

    PASSWORD_LIMIT = 1_000
    USERNAME_LIMIT = 50_000

    WEAK_SCORE = 35
    STRONG_SCORE = 70
    MAXIMUM_SCORE = 100

    # The constants the three included modules define, such as WEAK and
    # SYMBOL_RE, resolve through the ancestors, so code written against
    # PasswordStrength::Base::SYMBOL_RE still finds them.

    # Hold the username that will be matched against password.
    attr_accessor :username

    # The password that will be tested.
    attr_accessor :password

    # The score for the latest test. Will be +nil+ if the password has not been tested.
    attr_reader :score

    # The ActiveRecord instance.
    # It only makes sense if you're creating a custom ActiveRecord validator.
    attr_reader :record

    # Set what characters cannot be present on password.
    # Can be a regular expression or array.
    #
    #   strength = PasswordStrength.test("john", "password with whitespaces", exclude: [" ", "asdf"])
    #   strength = PasswordStrength.test("john", "password with whitespaces", exclude: /\s/)
    #
    # Then you can check the test result:
    #
    #   strength.valid?(:weak)
    #   #=> false
    #
    #   strength.status
    #   #=> :invalid
    #
    attr_accessor :exclude

    # The minimum number of characters a password must have. A password shorter
    # than this is rejected outright (status +:invalid+), whatever score its
    # other characteristics would earn. Leave it +nil+ to apply no hard
    # minimum, in which case a password under six characters is only penalised
    # through the score.
    #
    #   strength = PasswordStrength.test("johndoe", "^P4ss$", min_length: 12)
    #   strength.status
    #   #=> :invalid
    #
    #   strength.invalid_reason
    #   #=> :too_short
    #
    attr_accessor :min_length

    def initialize(username, password, options = {})
      @username = username.to_s[0...USERNAME_LIMIT]
      @password = password.to_s[0...PASSWORD_LIMIT]
      @score = 0
      @exclude = options[:exclude]
      @record = options[:record]
      @min_length = options[:min_length]
    end

    # Check if the password has fewer characters than
    # PasswordStrength::Base#min_length. Always false when no minimum has been
    # set.
    def too_short?
      return false unless min_length

      password.size < min_length
    end

    # Run all tests on password and return the final score.
    def test
      @score = 0
      @invalid_reason = nil
      reason = rejection_reason

      if reason
        invalid!(reason)
        return score
      end

      @score = total_score
      classify

      score
    end

    def contain_invalid_matches? # :nodoc:
      return false unless exclude

      regex = exclude
      regex = /#{exclude.collect { |i| Regexp.escape(i) }.join('|')}/ if exclude.is_a?(Array)
      password.to_s.match?(regex)
    end

    def contain_invalid_repetion? # :nodoc:
      text = password.to_s
      char = text[0]
      return false unless char

      text.each_char.all? { |other| other.casecmp?(char) }
    end

    private

    # The reason to reject the password outright, or nil when it is worth
    # scoring.
    def rejection_reason
      return :too_short if too_short?
      return :excluded_characters if contain_invalid_matches?
      return :common_word if common_word?
      return :repeated_character if contain_invalid_repetion?

      nil
    end

    def total_score
      total = Scoring::RULE_METHODS.sum { |rule| send(rule) }

      total.clamp(0, MAXIMUM_SCORE)
    end

    def classify
      if score < WEAK_SCORE
        weak!
      elsif score < STRONG_SCORE
        good!
      else
        strong!
      end
    end
  end
end
