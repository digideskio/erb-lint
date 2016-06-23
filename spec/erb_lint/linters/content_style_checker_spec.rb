# frozen_string_literal: true

require 'spec_helper'
require 'YAML'

describe ERBLint::Linter::ContentStyleChecker do
  let(:linter_config) do
    {
      'rule_set' => rule_set,
      'addendum' => 'Questions? Contact #product-content on Slack or @Shopify/product-content on GitHub.'
    }
  end

  let(:linter) { described_class.new(linter_config) }

  subject(:linter_errors) { linter.lint_file(ERBLint::Parser.parse(file)) }

  let(:rules) { <<~FILE }
  ---

  - violation:
      - 'dropdown'
      - 'drop down'
    case_insensitive: true
    suggestion: "drop-down"

  - violation:
      - 'Shopify partner'
    suggestion: 'Shopify Partner'

  - violation:
      - 'Shopify partners'
    suggestion: 'Shopify Partners'

  - violation:
      - 'manual'
      - 'Shopify manual'
      - 'docs'
      - 'documentation'
      - 'support docs'
    case_insensitive: true
    suggestion: 'Shopify Help Center'

  - violation:
      - 'Help Center'
      - 'help center'
    suggestion: 'Shopify Help Center'

  - violation:
      - 'theme store'
      - 'Theme Store'
    suggestion: 'Shopify theme store'

  - violation: 'Theme'
    suggestion: 'theme'

  - violation: 'Themes'
    suggestion: 'themes'

  - violation:
      - 'store’s admin'
      - "store's admin"
      - 'backend store admin'
      - 'back-end store admin'
      - 'admin'
    case_insensitive: true
    suggestion: 'Shopify admin'

  - violation: 'Shopify Admin'
    suggestion: 'Shopify admin'

  - violation: 'Store'
    suggestion: 'store'

  - violation: 'Stores'
    suggestion: 'stores'

  - violation:
      - 'application'
      - 'applications'
    case_insensitive: true
    suggestion: 'app'

  - violation:
      - 'applications'
    case_insensitive: true
    suggestion: 'apps'

  - violation:
      - 'App'
    suggestion: 'app'

  - violation:
      - 'Apps'
    suggestion: 'apps'

  - violation:
    - 'Payment Gateway'
    - 'payment-gateway'
    suggestion: 'payment gateway'

  - violation:
      - 'Payment Gateways'
      - 'payment-gateways'
    suggestion: 'payment gateways'

    FILE

  let(:rule_set) do
    # require 'pry'
    # binding.pry
    YAML.load(rules)
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

    context '- suggestion is prefix + violation (`Shopify Help Center`)
    - file contains suggestion (`Shopify Help Center`)
    - file contains violation (`Help Center`)' do
      let(:file) { <<~FILE }
        <p>Help! I need a Shopify Help Center. Not just any Help Center. Help!</p>

      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports error for `Help Center` and suggests `Shopify Help Center`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Help Center`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify Help Center`'
      end
    end

    context '- file contains suggestion (`Shopify Help Center`)
    - file contains violation (`help center`)' do
      let(:file) { <<~FILE }
        <p>Help. I need a Shopify Help Center. Not just any help center. Help.</p>

      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports error for `help center` and suggests `Shopify Help Center`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `help center`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify Help Center`'
      end
    end

    context '- suggestion is prefix + violation (`Shopify theme store`)
    - file contains violation (`theme store`)
    - file contains violation (`Theme store`)
    - violation contained in prior violation (`Theme`)' do
      let(:file) { <<~FILE }
        <p>The theme store called. They are out of themes at the Theme Store.</p>

      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'reports errors for `theme store` and `Theme Store` and suggests `Shopify theme store`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `theme store`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify theme store`'
        expect(linter_errors[1][:message]).to include 'Don\'t use `Theme Store`'
        expect(linter_errors[1][:message]).to include 'Do use `Shopify theme store`'
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

    context '- violation has multiple words and first word starts with uppercase character (`Shopify partner`)
    - suggestion has multiple words, both starting with uppercase characters (`Shopify Partner`)' do
      let(:file) { <<~FILE }
        <p>Are you a Shopify partner, partner?</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Shopify partner` and suggests `Shopify Partner`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Shopify partner`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify Partner`'
      end
    end

    context '- violation has a single dumb quote (`Store\'s admin`)' do
      let(:file) { <<~FILE }
        <p>Does the Store's admin add Finn?</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `store\'s admin` and suggests `Shopify admin`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `store\'s admin`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify admin`'
      end
    end

    context '- violation has a single smart quote (`Store’s admin`)
    - violation contained in prior violation' do
      let(:file) { <<~FILE }
        <p>Is the Store’s admin named Finn?</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      # TODO: Capture the real violation and push that instead of the violated rule?

      it 'reports errors for `store’s admin` and suggests `Shopify admin`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `store’s admin`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify admin`'
      end
    end

    context '- file has two double dumb quotes (`"backend store admin"`)' do
      let(:file) { <<~FILE }
        <p>Does the "backend store admin" add Finn?</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      # TODO: I also need to make it scan the entire rule worth of violations so it doesn't have to go in order.

      it 'reports errors for `backend store admin` and suggests `Shopify admin`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `backend store admin`'
        expect(linter_errors[0][:message]).to include 'Do use `Shopify admin`'
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
