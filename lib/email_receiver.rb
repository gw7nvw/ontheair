#!/usr/bin/env ruby
# frozen_string_literal: true

# typed: true
require 'rubygems'
require 'resque'
require 'redis'
require 'mail'

class EmailReceive
  @queue = :ontheair

  def initialize(content)
    mail    = Mail.read_from_string(content)
    from    = mail.from.first
    to      = mail.to.first
    subject = mail.subject
    attachment = nil
    file = nil

    if mail.multipart?
      part = begin
               mail.parts.select { |p| p.content_type =~ /text\/plain/ }.first
             rescue StandardError
               nil
             end
      attachment = begin
                     mail.parts.select { |p| p.content_type =~ /application\/octet-stream/ }.first
                   rescue StandardError
                     nil
                   end
      file = attachment.decoded if attachment
      message = part.body.decoded unless part.nil?
    else
      message = mail.decoded
    end

    unless message.nil?
      Resque.enqueue(EmailReceive, from, to, subject, message, file)
    end
  end
end

EmailReceive.new($stdin.read)
