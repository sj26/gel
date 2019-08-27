#!/usr/bin/env ruby
# frozen_string_literal: true

class Gel::Command::Grep < Gel::Command
  def run(command_line)
    command =
      if system "which", "ag", out: :close, err: :close
        ["ag"]
      else
        ["grep", "-r"]
      end

    while command_line.first.start_with? "-"
      if command_line.first == "--"
        command_line.shift
        break
      else
        command << command_line.shift
      end
    end

    pattern = command_line.shift

    raise "Unknown arguments: #{command_line.inspect[1...-1]}" unless command_line.empty?

    Gel::Environment.activate(output: $stderr)

    dirs = Gel::Environment.activated_gems.values.flat_map(&:require_paths)

    exec *command, pattern, *dirs
  end
end
