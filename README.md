# ERB Lint [![Build Status](https://travis-ci.org/Shopify/erb-lint.svg?branch=master)](https://travis-ci.org/Shopify/erb-lint)

`erb-lint` is a tool to help lint your ERB or HTML files using the included linters or by writing your own.

## Requirements

* Ruby 2.2.0+ (Runtime)
* Ruby 2.3.0+ (Development)
 - This is due to the use of the tilde-heredoc `<<~` syntax in some tests.

## Installation

```bash
gem install erb_lint
```

...or add the following to your `Gemfile` and run `bundle install`:

```ruby
gem 'erb_lint'
```

## Usage

1. First instantiate a Runner with or without a configuration.

  ```ruby
  runner = ERBLint::Runner.new() # uses default configs
  ```
  
  Use configurations to specify which Linters you want to use. Configuration details can be found [here](#configuration).

  ```ruby
  config = {
    'linters' => {
      'FinalNewline' => {
        'enabled' => true
      }
    }
  }
  runner = ERBLint::Runner.new(config)
  ```


2. Now, we can run the Runner against a file:
  ```erb
  <!-- file.html.erb -->
  <div class="foo"></div>
  ```

  ```ruby
  file = File.read('file.html.erb')
  violations = runner.run(file)
  ```
  
  The runner returns a violation list containing each linter that was run and its corresponding list of errors.
  ```ruby
  violations
  # => [{
  #   linter_name: 'FinalNewline',
  #   errors: [
  #     { line: 1, message: 'Missing a trailing newline at the end of the file.' }
  #   ]
  # }]
  ```

## Configuration

The general format for the configuration is:

```ruby
config = {
  'linters' => {
    'Linter1' => {
      'enabled' => true,
      'linter_specific_option' => 'value',
      ...
    },
    
    'Linter2' => {
      'enabled' => false,
      'linter_specific_option' => 'value',
      ...
    }
  }
}
```

All linters have an `enabled` option which can be `true` or `false`, which
controls whether the linter is run, along with linter-specific options.

The default configuration is:

```ruby
default_config = {
  'linters' => {
    'FinalNewline' => {
      'enabled' => true
    }
  }
}
```

which gets used when you create a `Runner` with no config.

## Linters

`erb-lint` comes with 3 linters on-board: `DeprecatedClasses`, `FinalNewline`, and `UnwantedTextContent`, each with their own linter-specific options.

### DeprecatedClasses

DeprecatedClasses will find all classes used on HTML elements and report any classes that violate the rule set that you provide.

This `rule_set` is specified as a list of rules each with a set of `deprecated` classes and a corresponding `suggestion`.

```ruby
'rule_set' => [
  {
    'deprecated' => ['class1', 'class2'],
    'suggestion' => "Use class3 instead!"
  },
  {
    'deprecated' => ['regular-expressions-*', 'size--\d+'],
    'suggestion' => "Hey aren't regular expressions neat?"
  }
]
```
You can also specify an addendum to be added to the end of each error message using the `addendum` option.
The error message format is: `"Deprecated class ... #{suggestion}"`
or `"Deprecated class ... #{suggestion} #{addendum}"` if an `addendum` is present.

Linter-Specific Option | Description
-----------------------|-----------------------------------------------------------------------------------
`rule_set`             | A list of rules, each with a `deprecated` and `suggestion` option.
`deprecated`           | A list of **regular expressions** which specify the classes deprecated by this rule.
`suggestion`           | A string to be included in the rule's error message. Make this informative and specific to the rule that it is contained in.
`addendum`             | A string to be included at the end of every error message of the rule set. (Optional)

### FinalNewline

Files should always have a final newline. This results in better diffs when
adding lines to the file, since SCM systems such as git won't think that you
touched the last line.

You can customize whether or not a final newline exists with the `present`
option.

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`present`              | Whether a final newline should be present (default **true**)

### UnwantedTextContent

Based on DeprecatedClasses, UnwantedTextContent will find any words or phrases that violate the rule set that you provide.

This `rule_set` is specified as a list of rules, each with a `violation` set and
a corresponding `suggestion`. You can also optionally add a `case_insensitive:
true` value to make UnwantedTextContent look for the violating terms in any
case.

Unlike DeprecatedClasses, UnwantedTextContent does not currently accept regular expressions.

```ruby
'rule_set' => [
  {
    'violation' => ['application', 'program'],
    'suggestion' => "app"
    'case_insensitive' => true
  },
  {
    'violation' => ['support page'],
    'suggestion' => "Lintercorp Help Center"
  }
]
```

You can also specify an addendum to be added to the end of each error message using the `addendum` option.
The error message format is: `"Don't use #{violation}. Do use #{suggestion}"`
or `"Don't use #{violation}. Do use #{suggestion}. #{addendum}"` if an `addendum` is present.

Linter-Specific Option | Description
-----------------------|-----------------------------------------------------------------------------------
`rule_set`             | A list of rules, each with a `violation` and `suggestion` option.
`violation`            | A list of strings that specify unwanted text content.
`suggestion`           | A suggested replacement for the unwanted text content defined in `violation`.
`case_insensitive`     | A Boolean value that determines whether the rule is case sensitive. (Optional, defaults to false if not included)
`addendum`             | A string to be included at the end of every error message of the rule set. (Optional)

## Custom Linters

`erb-lint` allows you to create custom linters specific to your project. It will load linters from the `.erb-linters` directory in the root of your
repository. See the [linters directory](lib/erb_lint/linters) for examples of how to write
linters. **Don't forget to enable the linter in the configuration!**

```ruby
# .erb-linters/another_linter.rb

module ERBLint
  class Linter::AnotherLinter < Linter
    include LinterRegistry
    ...
  end
end
```

```ruby
config = {
  'linters' => {
    ...
    'AnotherLinter' => {
      'enabled' => true,
      'linter_specific_option' => 'value',
      ...
    }
    ...
  }
}
```

## Contributing
1. Fork this repo.
2. Create a new branch. `git checkout -b new-branch-name`
3. Add and commit your changes. `git add .` `git commit -m "Added these cool things."`
4. Push to Github. `git push -u origin new-branch-name`
5. Create a Pull Request on this repo against your branch.

Please write tests!

To run tests:

1. run `bundle install` to install `rspec`

2. `bundle exec rspec spec` to run the test suite.

## License

This project is released under the [MIT license](LICENSE.txt).
