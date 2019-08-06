# frozen_string_literal: true

require "shellwords"

class Gel::Command::Open < Gel::Command
  def run(command_line)
    raise "Please provide the name of a gem to open in your editor" if command_line.empty?
    raise "Too many arguments, only 1 gem name is supported" if command_line.length > 1

    editor = ENV.fetch("GEL_EDITOR", ENV["EDITOR"])
    raise "An editor must be set using either $GEL_EDITOR or $EDITOR" unless editor

    Gel::Environment.activate(output: $stderr)

    found_gem = Gel::Environment.find_gem(command_line.first)
    raise "Can't find gem `#{command_line.first}`" unless found_gem

    command = [*Shellwords.split(editor), found_gem.root]
    exec(*command)
  end
end
