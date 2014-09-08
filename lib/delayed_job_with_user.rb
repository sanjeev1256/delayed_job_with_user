require 'delayed_job'
require 'active_support/concern'
require 'delayed_job_callbacks'

module DelayedJobWithUser
  extend ActiveSupport::Concern

  class JobWithUser
    include Delayed::Callbacks::Executor

    attr_accessor :object, :method_name, :args

    def initialize(object, method_name, args)
      raise NoMethodError, "undefined method `#{method_name}' for #{object.inspect}" unless object.respond_to?(method_name, true)

      if object.respond_to?(:new_record?) && object.new_record?
        raise(ArgumentError, 'Jobs cannot be created for records before they\'ve been persisted')
      end

      @object = object
      @args = args
      @method_name = method_name.to_sym
    end

    def inspect
      "#{@object.class}::#{@method_name}(#{@args.join(",")})"
    end

    def enqueue(job)
      self.execute_callbacks(:enqueue, job, nil)
    end

    def before(job)
      begin
        User.current_user = User.find(job.started_by)
        time_zone = User.current_user.person.time_zone rescue Time.zone.name
        time_zone_is_valid = time_zone.present? && ActiveSupport::TimeZone.all.include?(ActiveSupport::TimeZone.new(time_zone))
        Time.zone = time_zone if time_zone_is_valid
      rescue Exception => e
        # "Could not find User with id #{job.started_by}!"
        # TODO: handle this!
        # A user is not always required here, so it would be a bad practice to re-raise exception
        # But we need to inform somehow, that user wasn't found
      end

      self.execute_callbacks(:before, job, nil)
    end

    def after(job)
      self.execute_callbacks(:after, job, nil)
    end

    def success(job)
      self.execute_callbacks(:success, job, nil)
    end

    def error(job, exception)
      self.execute_callbacks(:error, job, exception)
    end

    def failure(job)
      self.execute_callbacks(:failure, job, nil)
    end

    def perform
      @object.send(method_name, *args) if @object
    end
  end

  class Proxy
    def initialize(target, options)
      @target = target
      @options = options
      @user_id = User.current_user.id rescue -1 # Sometimes `current_user` is `:false`
    end

    def method_missing(method, *args)
      job = Delayed::Job.enqueue({:payload_object => JobWithUser.new(@target, method.to_sym, args)}.merge(@options))
      job.update_attribute(:started_by, @user_id)
    end
  end

  module MessageSending
    def delay(options = {})
      Proxy.new(self, options)
    end
  end
end

Object.send(:include, DelayedJobWithUser::MessageSending)
