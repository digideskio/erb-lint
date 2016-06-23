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
        @prior_violations = []
      end

      def lint_file(file_tree)
        errors = []
        inner_text = select_text_children(html_elements(file_tree))
        inner_text ||= []
        outer_text = select_text_children(file_tree)
        outer_text ||= []
        all_text = (outer_text + inner_text)
        # Assumes the immediate parent is on the same line for demo purposes, otherwise hardcode line_number
        all_text.each do |text_node|
          line_number = text_node.parent.line unless text_node.parent.nil?
          push_errors(errors, text_node, line_number)
        end
        errors
      end

      private

      def push_errors(errors, text_node, line_number)
        errors.push(*generate_errors(text_node.text, line_number))
      end

      def select_text_children(source)
        source.children.select(&:text?)
      end

      def html_elements(file_tree)
        Nokogiri::XML::NodeSet.new(file_tree.document, file_tree.search('*'))
      end

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
          all_text = all_text.gsub(/#{suggestion}/, '')
          next if @prior_violations.to_s.match(/#{violation}/)
          if content_rule[:case_insensitive] == 'true'
            case_insensitive_match(violation, all_text)
          elsif content_rule[:case_insensitive] != 'true' && lc_uc(suggestion, violation)
            ignore_starting_caps_match(violation, all_text)
          else
            case_sensitive_match(violation, all_text)
          end
        end
      end

      def case_insensitive_match(violation, all_text)
        ci = /(#{violation})\b/i
        ci.match(all_text) && record_prior_violation(ci, all_text)
      end

      def case_sensitive_match(violation, all_text)
        cs = /(#{violation})\b/
        cs.match(all_text) && record_prior_violation(cs, all_text)
      end

      def ignore_starting_caps_match(violation, all_text)
        ic = /\w (#{violation})\b/
        ic.match(all_text) && record_prior_violation(ic, all_text)
      end

      def lc_uc(suggestion, violation)
        suggestion.match(/\p{Lower}/) && !violation.match(/\p{Lower}/)
      end

      def record_prior_violation(match_type, all_text)
        @prior_violations.push(match_type.match(all_text).captures)
      end
    end
  end
end
