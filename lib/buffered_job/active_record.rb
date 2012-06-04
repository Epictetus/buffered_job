# -*- coding: utf-8 -*-

class BufferedJob < ActiveRecord::Base
  after_create :set_delayed_job
  DEFAULT_DELAY_TIME = 3.minutes
  @@delay_time = DEFAULT_DELAY_TIME

  def self.delay_time=(sec)
    @@delay_time = sec
  end

  def self.reset_delay_time
    @@delay_time = DEFAULT_DELAY_TIME
  end

  def self.buf(params)
    params[:receiver] = YAML.dump params[:receiver]
    params[:target] = YAML.dump params[:target]
    self.create(params)
  end

  def self.mailer?(obj)
    obj.respond_to?(:superclass) and obj.superclass == ActionMailer::Base
  end

  def self.flush!
    return if locked?
    lock!
    jobs = self.all
    skip = []
    @last_results = []
    jobs.each do |j|
      if skip[j.id]
        j.destroy
        next 
      end
      cojobs = jobs.select{ |o| o.user_id = j.user_id and o.category == j.category }
      receiver = YAML.load(j.receiver)
      if cojobs.size > 1
        begin
          targets = cojobs.map{|c|
            YAML.load(c.target)
          }
          if mailer?(receiver)
            r = receiver.send(j.merge_method,targets).deliver
          else
            r = receiver.send(j.merge_method,targets)
          end
        rescue => er
          $stderr.puts er.to_s
        end
        cojobs.each do |c|
          skip[c.id] = true
        end
      else
        begin
          target = YAML.load(j.target)
          if mailer?(receiver)
            r = receiver.send(j.method,target).deliver
          else
            r = receiver.send(j.method,target)
          end
        rescue => er
        end
      end
      j.destroy
      @last_results << r
    end
    unlock!
  end

  def self.last_results
    @last_results or []
  end

  def self.lock!
    Rails.cache.write("mail_buffer_lock",true,:expires_in => 10.minutes)
  end

  def self.unlock!
    Rails.cache.delete("mail_buffer_lock")
  end

  def self.locked?
    Rails.cache.exist?("mail_buffer_lock")
  end

  private
  def set_delayed_job
    delay_time = @@delay_time or DEFAULT_DELAY_TIME
    self.class.delay(:run_at => delay_time.from_now).flush!
  end

  class Proxy
    def initialize(receiver,user,opt={})
      @receiver = receiver
      @user = user
      @opt = opt
    end
    
    def method_missing(method,target)
      cat =  @opt[:category] 
      cat ||= ( @receiver.class == Class ? @receiver.to_s : @receiver.class.to_s) + '#' + method.to_s
      merge_method = @opt[:action] || "merge_#{method}".to_sym
      BufferedJob.buf(:user_id => @user.id,
                     :category => cat,
                     :receiver => @receiver,
                     :method => method.to_sym,
                     :merge_method => merge_method,
                     :target => target)
    end
  end

  module Util
    def buffer_for(user,opt={})
      Proxy.new(self,user,opt)
    end

    def buffer(opt={})
      raise NoBufferTargetError unless self.respond_to?(:user)
      raise NoBufferTargetError unless self.user
      buffer_for(self.user,opt)
    end
  end

  class NoBufferTargetError < StandardError
  end
end


ActionMailer::Base.send(:extend,BufferedJob::Util)





