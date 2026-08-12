# frozen_string_literal: true

require 'test_helper'
require 'password_strength/javascript_source'

class TestJavascriptSource < Minitest::Test
  def test_the_checked_in_javascript_matches_the_ruby_data
    on_disk = File.read(PasswordStrength::JavascriptSource::PATH)

    assert_equal PasswordStrength::JavascriptSource.render(on_disk), on_disk,
                 'app/assets/javascripts/password_strength.js is out of date. Run `rake javascript`.'
  end

  def test_the_block_carries_the_whole_word_list
    assert_includes PasswordStrength::JavascriptSource.block, PasswordStrength::Blocklist.common_words.last
  end
end
