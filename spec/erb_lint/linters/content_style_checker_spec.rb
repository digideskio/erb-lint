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

  let(:rule_set) do
    YAML.load(File.read('config_test.yml')).to_a
  end

  context '1)
  - rule is case-insensitive
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

  context '2)
  - suggestion is prefix + violation (`Shopify Help Center`)
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

    context '3)
  - file contains suggestion (`Shopify Help Center`)
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

  context '4)
  - suggestion is prefix + violation (`Shopify theme store`)
  - file contains violation (`theme store`)
  - file contains violation ' do
    let(:file) { <<~FILE }
      <p>The theme store called. They are out of themes at the Theme Store.</p>

    FILE

    it 'reports 2 errors' do
      expect(linter_errors.size).to eq 2
    end

#     # TODO: Collision between "theme" and "theme store", and "Store" and "theme store"

    it 'reports errors for `theme store` and `Theme Store` and suggests `Shopify theme store`' do
      expect(linter_errors[0][:message]).to include 'Don\'t use `theme store`'
      expect(linter_errors[0][:message]).to include 'Do use `Shopify theme store`'
      expect(linter_errors[1][:message]).to include 'Don\'t use `Theme Store`'
      expect(linter_errors[1][:message]).to include 'Do use `Shopify theme store`'
      end
  end

  context '5)
  - violation starts with uppercase character (`Apps`)
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

  context '6)
  - violation starts with uppercase character (`App`)
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

  context '7)
  - violation has multiple words starting with uppercase characters (`Payment Gateways`)
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

  context '8)
  - violation has multiple words and first word starts with uppercase character (`Shopify partner`)
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

  context '9)
  - violation has a single quote (`Store\'s admin`)' do
    let(:file) { <<~FILE }
      <p>Does the Store\'s admin add Finn?</p>
    FILE

    it 'reports 1 errors' do
      expect(linter_errors.size).to eq 1
    end

    it 'reports errors for `Store\'s admin` and suggests `Shopify admin`' do
    expect(linter_errors[0][:message]).to include 'Don\'t use `Store\'s admin`'
    expect(linter_errors[0][:message]).to include 'Do use `Shopify admin`'
    end
  end


end
