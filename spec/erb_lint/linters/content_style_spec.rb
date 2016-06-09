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

  violation_set_1 = ['dropdown menu', '[Dd]rop down menu']
  suggestion_1 = 'drop-down menu'
  violation_set_2 = ['[Ll]ight plan', 'lite plan']
  suggestion_2 = 'Lite plan'

  let(:rule_set) do
    [
      {
        'violation' => violation_set_1,
        'suggestion' => suggestion_1
      },
      {
        'violation' => violation_set_2,
        'suggestion' => suggestion_2
      }
    ]
  end

  context 'when the file contains a violation from set 1 or 2' do
    let(:file) { <<~FILE }
      <div>
        The dropdown menu and the Drop down menu, and the lite plan and Light plan, are not part of the plan.
      </div>
      <h1>
        heading text
      </h1>
    FILE

    it 'reports 4 errors' do
      expect(linter_errors.size).to eq 4
    end
  end
end
