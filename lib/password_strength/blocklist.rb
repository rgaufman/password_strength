# frozen_string_literal: true

module PasswordStrength
  # The list of passwords nobody may use, and the comparison that decides
  # whether the password someone typed is one of them in disguise.
  module Blocklist
    # Characters people substitute for letters, so that a blocklisted word is
    # still recognised when someone writes it as P@ssw0rd or l3tm31n.
    LEET_SUBSTITUTIONS = {
      '@' => 'a', '4' => 'a', '8' => 'b', '(' => 'c', '3' => 'e', '6' => 'g',
      '1' => 'i', '!' => 'i', '|' => 'i', '0' => 'o', '5' => 's', '$' => 's',
      '7' => 't', '+' => 't', '2' => 'z'
    }.freeze

    TRAILING_DIGITS_RE = /\d+\z/

    # The same table as the two arguments String#tr wants. Every key and value
    # is one character and none of the keys is a tr metacharacter, so the table
    # transfers verbatim and one pass replaces a per-character map.
    LEET_FROM = LEET_SUBSTITUTIONS.keys.join.freeze
    LEET_TO = LEET_SUBSTITUTIONS.values.join.freeze

    NON_ASCII_RE = /[^\x00-\x7F]/

    class << self
      # Return an array of strings that represents common passwords. The
      # default list is taken from several online sources (just Google for
      # 'most common passwords').
      #
      # Notable sources:
      #
      # * http://www.whatsmypass.com/the-top-500-worst-passwords-of-all-time
      # * http://elementdesignllc.com/2009/12/twitters-most-common-passwords/
      #
      # The current list has 3.6KB and is loaded into memory just once.
      def common_words
        @common_words ||= File.readlines(File.expand_path('../../support/common.txt', __dir__), chomp: true)
      end

      # The list someone supplied through PasswordStrength::Base.blocklist=, or
      # nil when the bundled list still applies.
      attr_reader :blocklist

      # Provide your own list of forbidden passwords, for example the breached
      # passwords you downloaded from Have I Been Pwned. Each entry is compared
      # in lower case, and the comparison also folds the character
      # substitutions in LEET_SUBSTITUTIONS, so an entry of "password" also
      # rejects "P@ssw0rd".
      #
      #   PasswordStrength::Base.blocklist = File.readlines("breached.txt", chomp: true)
      #
      # Set it to nil to go back to the bundled list of common passwords.
      def blocklist=(words)
        @blocklist = words
        @blocklist_set = nil
      end

      # The words a password is compared against, in the same lower case the
      # candidates are folded into, so an entry such as "DEFAULT" can match.
      def blocklist_set
        @blocklist_set ||= Set.new((blocklist || common_words).map { |word| word.to_s.downcase })
      end
    end

    # The readers and the writer, on any class that includes this module, so
    # PasswordStrength::Base.blocklist = [...] keeps working and a subclass sees
    # the same list.
    module ClassMethods
      def common_words = Blocklist.common_words
      def blocklist = Blocklist.blocklist

      def blocklist=(words)
        Blocklist.blocklist = words
      end

      def blocklist_set = Blocklist.blocklist_set
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Check the password against the blocklist. A password matches when it is
    # on the list as typed, when it is on the list once upper case and leet
    # substitutions are folded away, or when it is a listed word followed by
    # digits, which is how most people dress up a guessable password.
    def common_word? # :nodoc:
      list = self.class.blocklist_set

      blocklist_candidates(password).any? { |candidate| list.include?(candidate) }
    end

    # Every form of the password the blocklist is checked against.
    def blocklist_candidates(text) # :nodoc:
      normalised = text.to_s
      normalised = normalised.unicode_normalize(:nfkc) if normalised.match?(NON_ASCII_RE)
      normalised = normalised.downcase
      leet = normalised.tr(LEET_FROM, LEET_TO)

      [normalised, leet, normalised.sub(TRAILING_DIGITS_RE, ''), leet.sub(TRAILING_DIGITS_RE, '')]
        .reject(&:empty?)
        .uniq
    end
  end
end
