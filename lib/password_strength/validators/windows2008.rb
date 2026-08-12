# frozen_string_literal: true

module PasswordStrength
  module Validators
    # Validates a Windows 2008 password against the following rules:
    #
    # * Passwords cannot contain the user's account name or parts of the
    #   user's full name that exceed two consecutive characters.
    # * Passwords must be at least six characters in length.
    # * Passwords must contain characters from three of the following four
    #   categories: English uppercase characters (A through Z); English
    #   lowercase characters (a through z); Base 10 digits (0 through 9);
    #   Non-alphabetic characters (for example, !, $, #, %).
    #
    # Reference: http://technet.microsoft.com/en-us/library/cc264456.aspx
    #
    class Windows2008 < PasswordStrength::Base
      MINIMUM_LENGTH = 6
      MINIMUM_VARIETY = 3
      CATEGORIES = [/[A-Z]/, /[a-z]/, /[0-9]/, PasswordStrength::Base::SYMBOL_RE].freeze

      def test
        return invalid!(:too_short) if too_short? || password.size < MINIMUM_LENGTH
        return invalid!(:too_few_categories) if variety < MINIMUM_VARIETY
        return invalid!(:contains_username) if password_contains_username?

        strong!
      end

      # How many of the four character categories the password draws on.
      def variety
        CATEGORIES.count { |category| password.match?(category) }
      end

      def password_contains_username?
        0.upto(password.size - 1) do |i|
          substring = password[i, 3]
          return true if username.include?(substring)
        end

        false
      end
    end
  end
end
