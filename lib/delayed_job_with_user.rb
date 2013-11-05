require 'delayed_job'
require 'active_support/concern'

module DelayedJobWithUser
  extend ActiveSupport::Concern

  class JobWithUser
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

    def before(job)
      begin
        User.current_user = User.find(job.started_by)
      rescue Exception => e
        # "Could not find User with id #{job.started_by}!"
        # TODO: handle this!
        # A user is not always required here, so it would be a bad practice to re-raise exception
        # But we need to inform somehow, that user wasn't found
      end
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
