# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter::ContentStyle do
  let(:linter_config) do
    {
      'rule_set' => rule_set,
      'addendum' => "Questions? Contact #product-content on Slack or @Shopify/product-content on GitHub."
    }
  end

  let(:linter) { described_class.new(linter_config) }

  subject(:linter_errors) { linter.lint_file(ERBLint::Parser.parse(file)) }

  violation_set_1 = ['[Dd]ropdown menu', '[Dd]rop down menu']
  suggestion_1 = 'drop-down menu'
  violation_set_2 = ['^((?!Shopify Help Center).)*[Hh]elp [Cc]enter']
  suggestion_2 = 'Shopify Help Center'
  violation_condensed_2 = 'help center'
  violation_set_3 = ['lite plan', '[Ll]ight [Pp]lan']
  suggestion_3 = 'Lite plan'

  let(:rule_set) do
    [
      {
        'violation' => violation_set_1,
        'suggestion' => suggestion_1
      },
      {
        'violation' => violation_set_2,
        'suggestion' => suggestion_2,
        'violation_condensed' => violation_condensed_2
      },
      {
        'violation' => violation_set_3,
        'suggestion' => suggestion_3
      }
    ]
  end

  context 'when the file contains a violation from set 1 or 2' do
    let(:file) { <<~FILE }
      <p>You have tried Coke Zero, so now try the Shopify Light Plan</p>
      <p>The dropdown menu and the Drop down menu are cool.</p>
      <p>The Shopify help center increases conversion!</p>

    FILE

    it 'reports 4 errors' do
      expect(linter_errors.size).to eq 4
    end
  end
end
