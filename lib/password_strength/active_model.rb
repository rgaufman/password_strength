# frozen_string_literal: true

module ActiveModel # :nodoc:
  module Validations # :nodoc:
    class StrengthValidator < EachValidator # :nodoc: all
      def initialize(options)
        super(options.reverse_merge(level: :good, with: :username, using: PasswordStrength::Base))
      end

      def validate_each(record, attribute, value)
        return unless PasswordStrength.enabled

        strength = strength_for(record, value)
        strength.test
        return if strength.valid?(level(record))

        add_error(record, attribute, strength)
      end

      def check_validity!
        raise ArgumentError, 'The :with option must be supplied' unless options.include?(:with)

        check_exclude_validity!(options[:exclude])
        check_min_length_validity!(options[:min_length])
        check_level_validity!(options[:level])
        super
      end

      def level(record)
        if options[:level].respond_to?(:call)
          level = options[:level].call(record).to_sym
          check_level_validity!(level)
          level
        else
          options[:level]
        end
      end

      private

      def strength_for(record, value)
        options[:using].new(record.send(options[:with]), value,
                            exclude: options[:exclude],
                            record: record,
                            min_length: options[:min_length])
      end

      def add_error(record, attribute, strength)
        if strength.invalid_reason == :too_short
          record.errors.add(attribute, :too_short, **options, count: strength.min_length)
        else
          record.errors.add(attribute, :too_weak, **options)
        end
      end

      def check_exclude_validity!(exclude)
        return if exclude.nil? || exclude.is_a?(Array) || exclude.is_a?(Regexp)

        raise ArgumentError, 'The :exclude options must be an array of strings or a regular expression'
      end

      def check_min_length_validity!(min_length)
        return if min_length.nil? || (min_length.is_a?(Integer) && min_length.positive?)

        raise ArgumentError, 'The :min_length option must be a positive integer'
      end

      def check_level_validity!(level)
        return if %i[weak good strong].include?(level) || level.respond_to?(:call)

        raise ArgumentError, 'The :level option must be one of [:weak, :good, :strong], a proc or a lambda'
      end
    end

    # Adds validates_strength_of to every model that includes
    # ActiveModel::Validations.
    module ClassMethods
      # Validates that the specified attributes are not weak (according to several rules).
      #
      #   class Person < ActiveRecord::Base
      #     validates_strength_of :password
      #   end
      #
      # The default options are <tt>:level => :good, :with => :username</tt>.
      #
      # If you want to compare your password against other field, you have to set the <tt>:with</tt> option.
      #
      #   validates_strength_of :password, :with => :email
      #
      # The available levels are: <tt>:weak</tt>, <tt>:good</tt> and <tt>:strong</tt>
      #
      # You can also provide a custom class/module that will test that password.
      #
      #   validates_strength_of :password, :using => CustomPasswordTester
      #
      # Your +CustomPasswordTester+ class should override the default implementation. In practice, you're
      # going to override only the +test+ method that must call one of the following methods:
      # <tt>invalid!</tt>, <tt>weak!</tt>, <tt>good!</tt> or <tt>strong!</tt>.
      #
      #   class CustomPasswordTester < PasswordStrength::Base
      #     def test
      #       if password != "mypass"
      #         invalid!
      #       else
      #         strong!
      #       end
      #     end
      #   end
      #
      # The tester above will accept only +mypass+ as password.
      #
      # PasswordStrength implements two validators: <tt>PasswordStrength::Base</tt> and <tt>PasswordStrength::Validators::Windows2008</tt>.
      #
      def validates_strength_of(*attr_names)
        validates_with StrengthValidator, _merge_attributes(attr_names)
      end
    end
  end
end
