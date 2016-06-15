# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter::ContentStyleChecker do
  let(:linter_config) do
    {
      'rule_set' => rule_set,
      'addendum' => 'Questions? Contact #product-content on Slack or @Shopify/product-content on GitHub.'
    }
  end

  let(:linter) { described_class.new(linter_config) }

  subject(:linter_errors) { linter.lint_file(ERBLint::Parser.parse(file)) }

  violation_set_1 = ['dropdown menu', 'drop down menu']
  suggestion_1 = 'drop-down menu'
  case_insensitive_1 = 'true'
  violation_set_2 = ['Help Center', 'help center']
  suggestion_2 = 'Shopify Help Center'
  violation_set_3 = ['timeline']
  suggestion_3 = 'gosh darn timeline'
  case_insensitive_3 = 'true'
  violation_set_4 = 'App'
  suggestion_4 = 'app'
  violation_set_5 = 'Application'
  suggestion_5 = 'application'

  let(:rule_set) do
    [
      {
        'violation' => violation_set_1,
        'suggestion' => suggestion_1,
        'case_insensitive' => case_insensitive_1
      },
      {
        'violation' => violation_set_2,
        'suggestion' => suggestion_2
      },
      {
        'violation' => violation_set_3,
        'suggestion' => suggestion_3,
        'case_insensitive' => case_insensitive_3
      },
      {
        'violation' => violation_set_4,
        'suggestion' => suggestion_4
      },
      {
        'violation' => violation_set_5,
        'suggestion' => suggestion_5
      }
    ]
  end

  context 'when a rule is case-insensitive and a file has a violation with a different case from the suggestion' do
    let(:file) { <<~FILE }
      <p>The drop-down menu increases conversion! But the Drop down menu does not.</p>

    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end
  end

  context 'when a violation is contained within a suggestion and a file contains a suggestion' do
    let(:file) { <<~FILE }
      <p>The Shopify Help Center is great.</p>

    FILE

    it 'reports 0 errors' do
      expect(linter_errors.size).to eq 0
    end
  end

  context 'when a violation is contained within a suggestion and a file contains a violation' do
    let(:file) { <<~FILE }
      <p>The Help Center is not helpful.</p>

    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end
  end

  # TODO: when a suggestion is contained in a violation

  # TODO: Plurals


  context 'when a rule is case-insensitive, a violation is contained within a suggestion, and a file contains a suggestion' do
    let(:file) { <<~FILE }
      <p>The Gosh Darn Timeline is skewed.</p>

    FILE

    it 'reports 0 errors' do
      expect(linter_errors.size).to eq 0
    end
  end

  context 'when a rule is case-insensitive, a violation is contained within a suggestion, and a file contains a violation' do
    let(:file) { <<~FILE }
      <p>The Timeline is skewed.</p>

    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end
  end

  context 'when a violation starts with an uppercase character, a suggestion starts with a lowercase character, and a file contains a violation and a false positive' do
    let(:file) { <<~FILE }
      <p>Big App. A Shopify app? App is good.</p>
    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end
  end


  context 'when a violation starts with an uppercase character, a suggestion starts with a lowercase character, and a file contains a true violation and a false positive' do
    let(:file) { <<~FILE }
      <p>App. A Shopify app? App is good. But App is bad.</p>
    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end
  end

  context 'when a violation starts with an uppercase character, a suggestion starts with a lowercase character, a suggestion is contained within a violation, and a file contains a true violation and a false positive' do
    let(:file) { <<~FILE }
      <p>Software application is an Application.</p>
    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end
  end

end

