# frozen_string_literal: true

require 'pry'

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
          (violation.is_a?(String) ? [violation] : violation).each do |violating_pattern|
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
        @prior_violations = []
        html_elements = Nokogiri::XML::NodeSet.new(file_tree.document, Parser.filter_erb_nodes(file_tree.search('*')))
        inner_text = html_elements.children.select { |node| node.text? }
        inner_text ||= []
        outer_text = file_tree.children.select { |node| node.text? }
        outer_text ||= []
        all_text = (outer_text + inner_text)
        # Assumes the immediate parent is on the same line for demo purposes, otherwise hardcode line_number
        all_text.each do |text_node|
          line_number = text_node.parent.line unless text_node.parent.nil?
          # binding.pry
          errors.push(*generate_errors(text_node.text, line_number))
        end
          # binding.pry
        errors
      end

      private

      def generate_errors(all_text, line_number)

        # Map matches to violations first??

        violated_rules(all_text).map do |violated_rule|
          violation = violated_rule[:violating_pattern]
          suggestion = violated_rule[:suggestion]

          {
            line: line_number,
            message: "Don't use `#{violation}`. Do use `#{suggestion}`. #{@addendum}".strip
          }
          # binding.pry
        end
      end

      def violated_rules(all_text)
        @content_ruleset.select do |content_rule|
          violation = content_rule[:violating_pattern]
          suggestion = content_rule[:suggestion]
          all_text = all_text.gsub(/#{suggestion}/, '') # .gsub(/"/, '') <= Strip out quotation marks from words
          lc_suggestion_uc_violation = suggestion.match(/\p{Lower}/) && !violation.match(/\p{Lower}/)
          next if @prior_violations.to_s.match(/#{violation}/)
          # next if this violation is contained within another one that has occurred earlier
          # in the list, e.g. "Store's admin" violates "store's admin" and "Store"
          if content_rule[:case_insensitive] == 'true'
            /(#{violation})\b/i.match(all_text) && @prior_violations.push(/(#{violation})\b/i.match(all_text).captures)
          elsif content_rule[:case_insensitive] != 'true' && lc_suggestion_uc_violation
            /\w (#{violation})\b/.match(all_text) && @prior_violations.push(/\w (#{violation})\b/.match(all_text).captures)
          else
            /(#{violation})\b/.match(all_text) && @prior_violations.push(/(#{violation})\b/.match(all_text).captures)
          end
        end
      end
    end
  end
end

