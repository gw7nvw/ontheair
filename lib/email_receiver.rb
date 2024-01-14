#!/usr/bin/env ruby
require 'rubygems'
require 'resque'
require 'redis'
require 'mail'

class EmailReceive
  @queue = :ontheair

  def initialize(content)
    mail    = Mail.read_from_string(content)
    body    = mail.body.decoded
    from    = mail.from.first
    to      = mail.to.first
    subject = mail.subject
    attachment = nil
    file = nil

    if mail.multipart?
      part = mail.parts.select { |p| p.content_type =~ /text\/plain/ }.first rescue nil
      attachment = mail.parts.select { |p| p.content_type =~ /application\/octet-stream/ }.first rescue nil
      if attachment then file=attachment.decoded end
      unless part.nil?
        message = part.body.decoded
      end
    else
      message = mail.decoded
    end

    unless message.nil?
      Resque.enqueue(EmailReceive, from, to, subject, message, file)
    end
  end
end

EmailReceive.new($stdin.read)

