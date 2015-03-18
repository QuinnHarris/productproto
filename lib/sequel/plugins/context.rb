class DBContextError < StandardError; end

class DBContext
  # Aspects
  # user
  # locale - (language, units, currency)
  # version
  # container
  @@inputs = {
      user: false,
      locale: false,
      version: false,
      container: false,
  }

  def initialize(parent, specified)
    @parent = parent
    @specified = specified.freeze
  end
  attr_reader :parent, :specified

  def user
    @specified[:user] || (parent && parent.user)
  end

  def locale
    return @specified[:locale] if @specified.has_key?(:locale)
    return parent.locale if parent && parent.locale
    return user.locale if user
    nil
  end

  def setup_context

  end

  def clean_context

  end


  @@current = nil
  def self.current!
    @@current
  end
  def self.current
    raise DBContextError, "No current context" unless @@current
    @@current
  end

  private def __apply__
    begin
      @@current = self
      Sequel::Model.db.transaction do
        setup_context
        yield ctx
      end
    ensure
      raise "Current Mismatch" unless @@current == self
      @@current = self.parent
      clean_context
    end
    self
  end

  # Use with caution, always close and open
  def self.apply_open!(opts = {})
    @@current = new(@@current, opts)
  end
  def self.apply_close!
    @@current = current.parent
  end

  def self.apply(opts = {}, &block)
    return current unless block_given?
    ctx = new(@@current, opts)
    ctx.__apply__(opts, &block)
  end

  def apply(opts, &block)
    ctx = current
    loop do
      raise "Context not in current stack" unless ctx
      break if ctx == self
      ctx = ctx.parent
    end
    return self unless block_given?
    ctx = self.class.new(self, opts)
    ctx.__apply__(opts, &block)
  end
end

module Sequel
  module Plugins
    module Context
      def self.configure(model, map)
        model.instance_eval do
          set_context_map map
        end
      end

      module ClassMethods
        def inherited_instance_variables
          super.merge(:@context_map=>:dup)
        end
        def set_context_map(map = {})
          @context_map = map.freeze
        end
        attr_reader :context_map
      end

      module InstanceMethods
        # Apply Context
        # Doesn't work right if you use your own model initializers
        def initialize(values = {})
          if @context = DBContext.current!
            context_values = {}
            self.class.context_map.each do |prop, meth|
              raise "Context value already set" if values.has_key?(prop)
              context_values[prop] = @context.send(meth)
            end
            # Ensures context values are enumerated first
            values = context_values.merge(values)
          end
          super values
        end
      end
    end
  end
end
