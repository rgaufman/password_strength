# frozen_string_literal: true

module PasswordStrength
  # The verdict a test reaches, and the readers and setters that report it.
  module Status
    INVALID = :invalid
    WEAK = :weak
    STRONG = :strong
    GOOD = :good

    # The current test status. Can be +:weak+, +:good+, +:strong+ or +:invalid+.
    attr_reader :status

    # The reason the password was marked invalid. One of +:too_short+,
    # +:common_word+, +:repeated_character+, +:excluded_characters+, or +nil+
    # when the password is not invalid.
    attr_reader :invalid_reason

    # Check if the password has the specified score.
    # Level can be +:weak+, +:good+ or +:strong+.
    def valid?(level = GOOD)
      case level
      when STRONG then strong?
      when GOOD then good? || strong?
      else !invalid?
      end
    end

    # Check if the password has been detected as strong.
    def strong?
      status == STRONG
    end

    # Mark password as strong.
    def strong!
      @status = STRONG
    end

    # Check if the password has been detected as weak.
    def weak?
      status == WEAK
    end

    # Mark password as weak.
    def weak!
      @status = WEAK
    end

    # Check if the password has been detected as good.
    def good?
      status == GOOD
    end

    # Mark password as good.
    def good!
      @status = GOOD
    end

    # Check if the password was rejected outright.
    def invalid?
      status == INVALID
    end

    # Mark password as invalid. The reason is optional and is exposed through
    # PasswordStrength::Status#invalid_reason so a caller can tell the person
    # what to fix.
    def invalid!(reason = nil)
      @invalid_reason = reason
      @status = INVALID
    end
  end
end
