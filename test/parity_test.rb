# frozen_string_literal: true

require 'test_helper'
require 'json'

# The Ruby half of the shared corpus in test/fixtures/parity.json. The
# JavaScript half reads the same file in test/js/password_strength.test.mjs, so
# a rule that changes on one side and not the other fails here or there.
class TestParity < Minitest::Test
  FIXTURE = JSON.parse(File.read(File.expand_path('fixtures/parity.json', __dir__)))

  FIXTURE['cases'].each do |example|
    define_method("test_#{example['password'].gsub(/\W/, '_')}") do
      strength = PasswordStrength.test(FIXTURE['username'], example['password'],
                                       min_length: FIXTURE['min_length'])

      assert_equal example['status'], strength.status.to_s, example['password']

      if example['reason']
        assert_equal example['reason'], strength.invalid_reason.to_s, example['password']
      else
        assert_nil strength.invalid_reason, example['password']
      end
    end
  end
end
