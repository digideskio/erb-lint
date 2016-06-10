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
      }
    ]
  end

  context 'when the file contains a violation from set 1 or 2' do
    let(:file) { <<~FILE }
      <div>
        The dropdown menu and the Drop down menu, and the Shopify help center are not part of the plan.
      </div>
      <h1>
        heading text
      </h1>
    FILE

    it 'reports 3 errors' do
      expect(linter_errors.size).to eq 3
    end
  end
end
