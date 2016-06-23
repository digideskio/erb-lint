# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter::ContentStyleChecker do
  let(:linter_config) do
    {
      'rule_set' => rule_set,
      'addendum' => 'Questions? Contact Lintercorp Product Content at product-content@lintercorp.com.'
    }
  end

  let(:linter) { described_class.new(linter_config) }

  subject(:linter_errors) { linter.lint_file(ERBLint::Parser.parse(file)) }

  let(:rule_set) do
    [
      { 'violation' => ['dropdown', 'drop down'],
        'case_insensitive' => true,
        'suggestion' => 'drop-down' },
      { 'violation' => ['Lintercorp partner'], 'suggestion' => 'Lintercorp Partner' },
      { 'violation' => ['Lintercorp partners'], 'suggestion' => 'Lintercorp Partners' },
      { 'violation' =>
       ['manual', 'Lintercorp manual', 'docs', 'documentation', 'support docs'],
        'case_insensitive' => true,
        'suggestion' => 'Lintercorp Help Center' },
      { 'violation' => ['Help Center', 'help center'],
        'suggestion' => 'Lintercorp Help Center' },
      { 'violation' => ['theme store', 'Theme Store'],
        'suggestion' => 'Lintercorp theme store' },
      { 'violation' => 'Theme', 'suggestion' => 'theme' },
      { 'violation' => 'Themes', 'suggestion' => 'themes' },
      { 'violation' =>
       ['store’s dashboard',
        'store\'s dashboard',
        'backend store dashboard',
        'back-end store dashboard',
        'dashboard'],
        'case_insensitive' => true,
        'suggestion' => 'Lintercorp dashboard' },
      { 'violation' => 'Lintercorp Dashboard', 'suggestion' => 'Lintercorp dashboard' },
      { 'violation' => 'Store', 'suggestion' => 'store' },
      { 'violation' => 'Stores', 'suggestion' => 'stores' },
      { 'violation' => ['application', 'applications'],
        'case_insensitive' => true,
        'suggestion' => 'app' },
      { 'violation' => ['applications'],
        'case_insensitive' => true,
        'suggestion' => 'apps' },
      { 'violation' => ['App'], 'suggestion' => 'app' },
      { 'violation' => ['Apps'], 'suggestion' => 'apps' },
      { 'violation' => ['Payment Gateway', 'payment-gateway'],
        'suggestion' => 'payment gateway' },
      { 'violation' => ['Payment Gateways'], 'suggestion' => 'payment gateways' }
    ]
  end

  context 'when the rule set is empty' do
    let(:rule_set) { [] }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any errors' do
        expect(linter_errors).to eq []
      end
    end
  end

  context 'when the rule set contains violations' do
    context '- rule is case-insensitive
    - file has violation with different case (`Drop down`)
    - file has violation with same case (`dropdown`)
    - file has suggestion (`drop-down`)' do

      let(:file) { <<~FILE }
        <p>Tune in, turn on, and drop-down out! And check out the Drop down and dropdown menu too.</p>

      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'reports errors for `Drop down` and `dropdown` and suggests `drop-down`, and ignores `drop-down`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `dropdown`'
        expect(linter_errors[0][:message]).to include 'Do use `drop-down`'
        expect(linter_errors[1][:message]).to include 'Don\'t use `drop down`'
        expect(linter_errors[1][:message]).to include 'Do use `drop-down`'
      end
    end

    context '- suggestion is prefix + violation (`Lintercorp Help Center`)
    - file contains suggestion (`Lintercorp Help Center`)
    - file contains violation (`Help Center`)' do
      let(:file) { <<~FILE }
        <p>Help! I need a Lintercorp Help Center. Not just any Help Center. Help!</p>

      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports error for `Help Center` and suggests `Lintercorp Help Center`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Help Center`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp Help Center`'
      end
    end

    context '- file contains suggestion (`Lintercorp Help Center`)
    - file contains violation (`help center`)' do
      let(:file) { <<~FILE }
        <p>Help. I need a Lintercorp Help Center. Not just any help center. Help.</p>

      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports error for `help center` and suggests `Lintercorp Help Center`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `help center`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp Help Center`'
      end
    end

    context '- suggestion is prefix + violation (`Lintercorp theme store`)
    - file contains violation (`theme store`)
    - file contains violation (`Theme store`)
    - violation contained in prior violation (`Theme`)' do
      let(:file) { <<~FILE }
        <p>The theme store called. They are out of themes at the Theme Store.</p>

      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'reports errors for `theme store` and `Theme Store` and suggests `Lintercorp theme store`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `theme store`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp theme store`'
        expect(linter_errors[1][:message]).to include 'Don\'t use `Theme Store`'
        expect(linter_errors[1][:message]).to include 'Do use `Lintercorp theme store`'
      end
    end

    context '- violation starts with uppercase character (`Apps`)
    - suggestion starts with lowercase character (`apps`)
    - file contains violation (`Big Apps`)
    - file contains two potential false positives (`Apps` starts the string and a sentence within the string)' do
      let(:file) { <<~FILE }
        <p>Apps, apps, and away. Big Apps and salutations to the Figure IV crew. Did Britney sing apps, I did it again? Apps a daisy.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Apps` and suggests `apps` but ignores the others' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Apps`'
        expect(linter_errors[0][:message]).to include 'Do use `apps`'
      end
    end

    context '- violation starts with uppercase character (`App`)
    - suggestion starts with lowercase character (`app`)
    - another violation contains this violation (`Apps`)
    - file contains a violation (`Five hundred App`)
    - file contains three potential false positives
      (`App` starts the string and a sentence within the string and `Apply` appears as well)' do
      let(:file) { <<~FILE }
        <p>App Apply. Five hundred App. App now, time is running out. Apply now.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `App` and suggests `app` but ignores the others' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `App`'
        expect(linter_errors[0][:message]).to include 'Do use `app`'
      end
    end

    context '- violation has multiple words starting with uppercase characters (`Payment Gateways`)
    - suggestion contains only lowercase characters (`payment gateways`)' do
      let(:file) { <<~FILE }
        <p>Payment Gateways are a gateway drug.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Payment Gateways` and suggests `payment gateways` but ignores the others' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Payment Gateways`'
        expect(linter_errors[0][:message]).to include 'Do use `payment gateways`'
      end
    end

    context '- violation has multiple words and first word starts with uppercase character (`Lintercorp partner`)
    - suggestion has multiple words, both starting with uppercase characters (`Lintercorp Partner`)' do
      let(:file) { <<~FILE }
        <p>Are you a Lintercorp partner, partner?</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Lintercorp partner` and suggests `Lintercorp Partner`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Lintercorp partner`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp Partner`'
      end
    end

    context '- violation has a single dumb quote (`Store\'s dashboard`)' do
      let(:file) { <<~FILE }
        <p>Welcome to the Store's dashboard.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `store\'s dashboard` and suggests `Lintercorp dashboard`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `store\'s dashboard`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp dashboard`'
      end
    end

    context '- violation has a single smart quote (`Store’s dashboard`)
    - violation contained in prior violation' do
      let(:file) { <<~FILE }
        <p>Welcome to the Store’s dashboard.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `store’s dashboard` and suggests `Lintercorp dashboard`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `store’s dashboard`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp dashboard`'
      end
    end

    context '- file has two double dumb quotes (`"backend store dashboard"`)' do
      let(:file) { <<~FILE }
        <p>Welcome to the "backend store dashboard".</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `backend store dashboard` and suggests `Lintercorp dashboard`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `backend store dashboard`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp dashboard`'
      end
    end

    context 'when an addendum is present' do
      let(:linter_config) do
        {
          'rule_set' => rule_set,
          'addendum' => addendum
        }
      end
      let(:addendum) { 'Addendum!' }

      context 'when the file is empty' do
        let(:file) { '' }

        it 'does not report any errors' do
          expect(linter_errors).to eq []
        end
      end

      context 'when the file contains a violation' do
        let(:file) { <<~FILE }
          <p>All about that App</p>
        FILE

        it 'reports 1 error' do
          expect(linter_errors.size).to eq 1
        end

        it 'reports an error with its message ending with the addendum' do
          expect(linter_errors.first[:message]).to end_with addendum
        end
      end
    end

    context 'when an addendum is absent' do
      let(:linter_config) do
        {
          'rule_set' => rule_set
        }
      end

      context 'when the file is empty' do
        let(:file) { '' }

        it 'does not report any errors' do
          expect(linter_errors).to eq []
        end
      end
    end
  end
end
