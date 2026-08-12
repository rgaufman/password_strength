# frozen_string_literal: true

module PasswordStrength
  # The scoring rules. Each rule looks at one characteristic of the password
  # and returns the points it adds to, or takes away from, the total.
  module Scoring
    MULTIPLE_NUMBERS_RE = /\d.*?\d.*?\d/
    MULTIPLE_SYMBOLS_RE = /[!@#$%^&*?_~-].*?[!@#$%^&*?_~-]/
    SYMBOL_RE = /[!@#$%^&*?_~-]/
    UPPERCASE_LOWERCASE_RE = /([a-z].*[A-Z])|([A-Z].*[a-z])/
    NUMBER_RE = /[0-9]/
    LETTER_RE = /[a-z]/i
    LETTERS_ONLY_RE = /^[a-z]+$/i
    NUMBERS_ONLY_RE = /^\d+$/

    # The rules PasswordStrength::Base#test applies, in the order it applies
    # them, each pointing at the method that scores it.
    RULES = {
      password_size: :score_password_size,
      numbers: :score_numbers,
      symbols: :score_symbols,
      uppercase_lowercase: :score_uppercase_lowercase,
      numbers_chars: :score_numbers_chars,
      numbers_symbols: :score_numbers_symbols,
      symbols_chars: :score_symbols_chars,
      only_chars: :score_only_chars,
      only_numbers: :score_only_numbers,
      username: :score_username,
      sequences: :score_sequences,
      repetitions: :score_repetitions
    }.freeze

    # Return the score for one of the rules in RULES. Asking for a rule that
    # does not exist raises, rather than scoring it as zero and hiding the typo.
    def score_for(name)
      rule = RULES[name.to_sym]
      raise ArgumentError, "Unknown scoring rule: #{name.inspect}. Known rules are #{RULES.keys.join(', ')}" unless rule

      send(rule)
    end

    # Count the sequences in the text, such as abc or 123, both of which are
    # cheap for someone else to guess.
    def sequences(text) # :nodoc:
      matches = 0
      run = 0
      previous = nil

      # Codepoints, not bytes: a multi-byte character such as é is one
      # character to the person typing it, and counting its bytes turns it into
      # a run that penalises the score.
      text.to_s.each_codepoint do |codepoint|
        run = previous && (codepoint == previous + 1 || codepoint == previous) ? run + 1 : 0
        matches += 1 if run == 2
        previous = codepoint
      end

      matches
    end

    # Count how many substrings of the given size appear more than once.
    def repetitions(text, size) # :nodoc:
      matches = []

      0.upto(text.size - 1) do |index|
        substring = text[index, size]

        next if matches.include?(substring) || substring.size < size

        matches << substring
      end

      matches.count { |substring| text.scan(/#{Regexp.escape(substring)}/).length > 1 }
    end

    private

    def score_password_size
      password.size < 6 ? -100 : password.size * 4
    end

    def score_numbers
      password.match?(MULTIPLE_NUMBERS_RE) ? 5 : 0
    end

    def score_symbols
      password.match?(MULTIPLE_SYMBOLS_RE) ? 5 : 0
    end

    def score_uppercase_lowercase
      password.match?(UPPERCASE_LOWERCASE_RE) ? 10 : 0
    end

    def score_numbers_chars
      password.match?(LETTER_RE) && password.match?(NUMBER_RE) ? 15 : 0
    end

    def score_numbers_symbols
      password.match?(NUMBER_RE) && password.match?(SYMBOL_RE) ? 15 : 0
    end

    def score_symbols_chars
      password.match?(LETTER_RE) && password.match?(SYMBOL_RE) ? 15 : 0
    end

    def score_only_chars
      password.match?(LETTERS_ONLY_RE) ? -15 : 0
    end

    def score_only_numbers
      password.match?(NUMBERS_ONLY_RE) ? -15 : 0
    end

    def score_username
      return -100 if password == username
      return -15 if password.match?(/#{Regexp.escape(username)}/)

      0
    end

    def score_sequences
      (-15 * sequences(password)) + (-15 * sequences(password.to_s.reverse))
    end

    def score_repetitions
      -((repetitions(password, 2) * 4) + (repetitions(password, 3) * 3) + (repetitions(password, 4) * 2))
    end
  end
end
