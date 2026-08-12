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

    # The length below which a password is penalised rather than scored on its
    # length. It is not the same thing as PasswordStrength::Base#min_length,
    # which rejects a password outright: this one only applies when no hard
    # minimum has been set.
    SHORT_PASSWORD_SIZE = 6

    # The rules PasswordStrength::Base#test applies, in the order it applies
    # them. Each is scored by the private method of the same name, prefixed
    # with "score_".
    RULES = %i[
      password_size numbers symbols uppercase_lowercase numbers_chars
      numbers_symbols symbols_chars only_chars only_numbers username
      sequences repetitions
    ].freeze

    RULE_METHODS = RULES.map { |rule| :"score_#{rule}" }.freeze

    # Return the score for one of the rules in RULES. Asking for a rule that
    # does not exist raises, rather than scoring it as zero and hiding the typo.
    def score_for(name)
      index = RULES.index(name.to_sym)
      raise ArgumentError, "Unknown scoring rule: #{name.inspect}. Known rules are #{RULES.join(', ')}" unless index

      send(RULE_METHODS[index])
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
      seen = Set.new

      0.upto(text.size - 1) do |index|
        substring = text[index, size]

        seen << substring unless substring.size < size
      end

      seen.count { |substring| repeated?(text, substring) }
    end

    private

    # Whether the substring appears more than once, counted the way String#scan
    # counts it: occurrences do not overlap, and the search stops at the second
    # one rather than collecting every match.
    def repeated?(text, substring)
      first = text.index(substring)

      !first.nil? && !text.index(substring, first + substring.size).nil?
    end

    def score_password_size
      password.size < SHORT_PASSWORD_SIZE ? -100 : password.size * 4
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
      return -15 if password.include?(username)

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
