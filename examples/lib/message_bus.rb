# frozen_string_literal: true

# message_bus.rb — Simple pub/sub message bus for robot collaboration
#
# Provides point-to-point delivery and broadcast messaging between
# registered robots. No SelfAgency dependency — plain infrastructure.


class MessageBus
  attr_reader :log

  def initialize
    @robots = {}
    @log    = []
  end

  def register(robot)
    @robots[robot.name] = robot
    puts "MessageBus: registered robot '#{robot.name}'"
  end

  def deliver(from:, to:, content:)
    recipient = @robots[to]
    unless recipient
      puts "MessageBus: unknown recipient '#{to}'"
      return
    end

    @log << { from: from, to: to, content: content }
    recipient.receive_message(from: from, content: content)
    puts "MessageBus: #{from} -> #{to} (#{content_preview(content)})"
  end

  def broadcast(from:, content:)
    @robots.each do |name, robot|
      next if name == from

      @log << { from: from, to: name, content: content }
      robot.receive_message(from: from, content: content)
    end
    puts "MessageBus: #{from} -> broadcast (#{content_preview(content)})"
  end

  def print_log
    puts "=== Message Bus Log (#{@log.size} messages) ==="
    @log.each_with_index do |entry, i|
      puts "  #{i + 1}. #{entry[:from]} -> #{entry[:to]}: #{content_preview(entry[:content])}"
    end
  end

  private

  def content_preview(content)
    text = content.to_s
    text.length > 80 ? "#{text[0, 77]}..." : text
  end
end
