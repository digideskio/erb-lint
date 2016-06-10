# frozen_string_literal: true

module ERBLint
  class Linter
    # Checks for content style guide violations in the text nodes of HTML files.
    class ContentStyle < Linter
      include LinterRegistry

      def initialize(config)
        @content_ruleset = []
        config.fetch('rule_set', []).each do |rule|
          suggestion = rule.fetch('suggestion', '')
          violation_string = rule.fetch('violation_condensed', '')
          rule.fetch('violation', []).each do |violating_pattern|
            @content_ruleset.push(
              violating_pattern: violating_pattern,
              suggestion: suggestion,
              violation_string: violation_string
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
        inner_text = inner_text || ''
        outer_text = file_tree.children.select { |node| node.text? }
        outer_text = outer_text || ''
        all_text = (outer_text + inner_text).to_s
        line_number = '6'
        errors.push(*generate_errors(all_text, line_number))
        errors
      end

      private

      def generate_errors(all_text, line_number)
        violated_rules(all_text).map do |violated_rule|
              suggestion = "#{violated_rule[:suggestion]}".rstrip
              violation = "#{violated_rule[:violating_pattern]}".rstrip
              violation_string = "#{violated_rule[:violation_string]}".rstrip
              unless violation_string == ''
                violation = violation_string
              end
          {
            line: line_number,
            message: "Do use '#{suggestion}'. Don't use '#{violation}'. #{@addendum}".strip
          }
        end
      end

      def violated_rules(all_text)
        @content_ruleset.select do |content_rule|
          /#{content_rule[:violating_pattern]}/.match(all_text)
        end
      end
    end
  end
end
