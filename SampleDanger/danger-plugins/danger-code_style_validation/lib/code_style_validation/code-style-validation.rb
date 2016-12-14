require "git_diff_parser"
require "pry"

def generate_markdown(title, content)
  markup_message = "####" + title + "\n"
  markup_message += "```\n" + content + "\n``` \n"
  markup_message
end

def resolve_diff(diff_str)
  # Parse all patches from diff string
  patches = GitDiffParser.parse(diff_str)

  markup_message = ""

  patches.each do |patch|
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
