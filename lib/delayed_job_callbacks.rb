require 'active_support/concern'

# TODO:
# - add support for procs
# - add support for before/after callbacks
# - utilize active_support/callbacks
module Delayed
  module Callbacks
    CALLBACK_HOOKS = [:enqueue, :before, :after, :success, :error, :failure]

    module Client
      extend ActiveSupport::Concern

      included do
        CALLBACK_HOOKS.each{ |hook| __define_callbacks(hook) }
      end

      module ClassMethods
        def __define_callbacks(hook)
          cb_var = "@@__callbacks_#{hook}"

          macro = Proc.new do |*args|
            __sanitize_callback_arguments!(args)
            class_variable_defined?(cb_var) ? class_variable_get(cb_var).push(args).uniq! : class_variable_set(cb_var, args)
          end

          self.class.send :define_method, "on_job_#{hook}", macro
        end

        def __sanitize_callback_arguments!(args)
          args.uniq!
          args.select!{ |arg| arg.is_a?(String) || arg.is_a?(Symbol) }
        end
      end
    end

    module Executor
      def execute_callbacks(hook, job, exception)
        object = job.payload_object.object
        callbacks = object.class.class_variable_get("@@__callbacks_#{hook}") rescue nil

        callbacks.each { |cb| object.send(cb, job, exception) } unless callbacks.nil?
      end
    end
  end
end
