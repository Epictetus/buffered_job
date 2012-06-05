# -*- coding: utf-8 -*-

module BufferedJob
  class Model < ActiveRecord::Base
    self.table_name = 'buffered_jobs'
    before_create :yaml_dump
    after_create :set_delayed_job
    
    def self.cache
      @@cache ||= defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
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
        cojobs = jobs.select{ |o| o.user_id == j.user_id and o.category == j.category }
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
            $stderr.puts er.to_s
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
      cache.write("mail_buffer_lock",true,:expires_in => 10.minutes)
    end
    
    def self.unlock!
      cache.delete("mail_buffer_lock")
    end
    
    def self.locked?
      cache.exist?("mail_buffer_lock")
    end
    
    private
    def yaml_dump
      self.receiver = YAML.dump self.receiver
      self.target = YAML.dump self.target
    end

    def set_delayed_job
      delay_time = BufferedJob.delay_time
      self.class.delay(:run_at => delay_time.from_now).flush!
    end
  end
end








