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
          rule.fetch('violation', []).each do |violating_text|
            @content_ruleset.push(
              violating_text: violating_text,
              suggestion: suggestion
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
          {
            line: line_number,
            message: "Do use #{suggestion}. Don't use #{violated_rule[:violating_text]}. #{@addendum}".strip
          }
        end
      end

      def violated_rules(all_text)
        @content_ruleset.select do |content_rule|
          /#{content_rule[:violating_text]}/.match(all_text)
        end
      end
    end
  end
end
