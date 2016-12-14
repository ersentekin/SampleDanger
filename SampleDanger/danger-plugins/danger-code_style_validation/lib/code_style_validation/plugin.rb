require "git_diff_parser"

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Ersen Tekin/danger-code_style_validation
  # @tags monday, weekends, time, rattata
  #
  class DangerCodeStyleValidation < Plugin
    def markdown_for_code_style_violation
      diff = ''
      case danger.scm_provider
      when :github
        diff = github.pr_diff
      when :gitlab
        diff = gitlab.mr_diff
      when :bitbucket_server
        diff = bitbucket_server.pr_diff
      end

      message = resolve_diff(diff)
      markdown message unless message.empty?
    end

    private

    def generate_markdown(title, content)
      markup_message = "####" + title + "\n"
      markup_message += "```\n" + content + "\n``` \n"
      markup_message
    end

    def resolve_diff(diff_str)
      # Parse all patches from diff string
      patches = GitDiffParser.parse(diff_str)

      markup_message = ''

      patches.each do |patch|
        file_extension = patch.file.split(//).last(2).join

        if file_extension != '.m' && file_extension != '.h'
          next
        end

        changed_lines_command_array = []

        patch.changed_line_numbers.each do |line_number|
          changed_lines_command_array.push("-lines=" + line_number.to_s + ":" + line_number.to_s)
        end

        changed_lines_command = changed_lines_command_array.join(" ")

        format_command_array = ["clang-format", changed_lines_command, patch.file]

        # clang-format command for formatting JUST changed lines
        formatted = `#{format_command_array.join(" ")}`

        formatted_temp_file = Tempfile.new('temp-formatted')
        formatted_temp_file.write(formatted)
        formatted_temp_file.rewind

        diff_command_array = ["diff ", patch.file, formatted_temp_file.path]

        # Generate diff string between formatted and original strings
        diff = `#{diff_command_array.join(" ")}`

        formatted_temp_file.close
        formatted_temp_file.unlink

        # generate Markup message of patch suggestions to prevent code-style violations
        unless diff.empty?
          markup_message += generate_markdown(patch.file, diff)
        end
      end

      markup_message
    end
  end
end
