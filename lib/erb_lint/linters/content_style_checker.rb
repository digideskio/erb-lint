# frozen_string_literal: true

module ERBLint
  class Linter
    # Checks for content style guide violations in the text nodes of HTML files.
    class ContentStyleChecker < Linter
      include LinterRegistry

      def initialize(config)
        @content_ruleset = []
        config.fetch('rule_set', []).each do |rule|
          suggestion = rule.fetch('suggestion', '')
          case_insensitive = rule.fetch('case_insensitive', '')
          violation = rule.fetch('violation', [])
          (violation.kind_of?(String) ? [violation] : violation).each do |violating_pattern|
            @content_ruleset.push(
              violating_pattern: violating_pattern,
              suggestion: suggestion,
              case_insensitive: case_insensitive
            )
          end
        end
        @content_ruleset.freeze

        @addendum = config.fetch('addendum', '')
      end

      def lint_file(file_tree)
        errors = []
        html_elements = Nokogiri::XML::NodeSet.new(file_tree.document, Parser.filter_erb_nodes(file_tree))
        inner_text = html_elements.children.select { |node| node.text? }
        inner_text = inner_text || []
        outer_text = file_tree.children.select { |node| node.text? }
        outer_text = outer_text || []
        all_text = (outer_text + inner_text)

        # Assumes the immediate parent is on the same line for demo purposes, otherwise hardcode line_number
        all_text.each do |text_node|
          line_number = text_node.parent.line if !text_node.parent.nil?
          errors.push(*generate_errors(text_node.text, line_number))
        end
        errors
      end

      private

      def generate_errors(all_text, line_number)
        violated_rules(all_text).map do |violated_rule|
          violation = violated_rule[:violating_pattern]
          suggestion = violated_rule[:suggestion]
          {
            line: line_number,
            message: "Don't use `#{violation}`. Do use `#{suggestion}`. #{@addendum}".strip
          }
        end
      end

      def violated_rules(all_text)
        @content_ruleset.select do |content_rule|
          violation = content_rule[:violating_pattern]
          suggestion = content_rule[:suggestion]
          violation_in_suggestion_i = /^(?:(?!#{suggestion}).)*(#{violation}\b)/i.match(all_text)
            # E.g., for violation "hyperlink" and suggestion "internets hyperlink", ignore "internets hyperlink"
          violation_in_suggestion = /^(?:(?!#{suggestion}).)*(#{violation}\b)/.match(all_text)
          ignore_starting_caps = /\w App/.match(all_text)
            # E.g., for violation "App" and suggestion "app", ignore starts of strings or sentences.
          case_insensitive = /(#{violation})\b/i.match(all_text)
          case_sensitive = /(#{violation})\b/.match(all_text)
          if content_rule[:case_insensitive] == 'true'
            # if rule is marked case_insensitive
            if /#{violation}/.match(suggestion)
              # if violation is contained in suggestion
              violation_in_suggestion_i
            else
              case_insensitive
            end
          elsif /#{violation}/.match(suggestion)
            # if violation is contained in suggestion
            violation_in_suggestion
          elsif suggestion[0,1] == suggestion[0,1].downcase && violation[0,1] == violation[0,1].upcase
            # if suggestion starts with a lowercase letter and violation starts with an uppercase letter
            ignore_starting_caps
          else
            case_sensitive
          end
        end
      end
    end
  end
end
