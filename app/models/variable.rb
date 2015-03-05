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
        def set_context_map(map)
          @context_map = map.freeze
        end
        attr_reader :context_map
      end

      module InstanceMethods
        # Apply Context
        # Doesn't work right if you use your own model initializers
        def initialize(values = {})
          if @context = DBContext.current!
            values = values.dup
            self.class.context_map.each do |prop, meth|
              raise "Context value already set" if values.has_key?(prop)
              values[prop] = @context.send(meth)
            end
          end
          super values
        end
      end
    end
  end
end


class Variable < Sequel::Model
  type_map = {
      PropertySingleNatural: :properties,
      PropertySingleString: nil,
      PropertySingleFloat: nil,
      PropertySingleInteger: nil,
      PropertySetNatural: [nil, 1 * 2**8],
      PropertySetString: nil,

      ValueNatural: [:value_naturals, 8 * 2**8],
      ValueString: :value_strings,
      ValueFloat: :value_floats,
      ValueInteger: :value_integers,

      PriceSingle: [:value_integers, 9 * 2**8],
      PriceReplaceDiscrete: :functions,
      PriceAddDiscrete: nil,
      PriceMultiplyDiscrete: nil,

      Assersion: [:assertions, 16 * 2**8],
      User: [:users, 16 * 2**8],
      ProductProperties: :assertions,
      Collection: nil,
      InstanceCollection: nil,
      ProductClass: nil,
      Product: nil,

      Instance: [:value_integers, 17 * 2**8 + 1],
      #Variable: :variables,

      AbstractPropertyValue: :variables,
      AbstractProperty: :properties,
      AbstractSingleProperty: nil,
      AbstractSetProperty: nil,
      AbstractValue: :values,
      AbstractPricing: nil,
      PriceDiscrete: :functions,
  }

  table_map = {}
  model_map = {}
  index = 0
  table = nil
  type_map.each do |c, v|
    t, i = Array(v)
    index = i || index
    table = t || table
    table_map[c] = table
    model_map[index] = c
    index += 1
  end
  #plugin :insert_returning_select
  plugin :improved_class_table_inheritance, key: :type, table_map: table_map, model_map: model_map

  many_to_one :created_user, class: :User
  many_to_one :locale

  one_to_many :predicates

  plugin :context, created_user: :user, locale: :locale

  plugin :pg_array_associations
  many_to_pg_array :provides, class: :Predicate, key: :dependent_ids

  def predicate_on(list)
    list = Array(list).flatten
    Predicate.create(variable: self, dependents: list)
  end

  def implies(var)
    var.predicate_on(self)
  end
end

class Predicate < Sequel::Model
  plugin :context, created_user: :user
  plugin :pg_array_associations

  many_to_one :variable
  pg_array_to_many :dependents, class: Variable
  def dependents=(list)
    ids = list.map do |obj|
      raise "Unexpected type" unless obj.is_a?(Variable)
      obj.id
    end
    set_column_value("dependent_ids=", Sequel.pg_array(ids))
  end

  many_to_one :created_user, class: :User
end

class ProductProperties < Variable

end

class AssertionRelation < Sequel::Model
  many_to_one :successor, class: :Assertion
  many_to_one :predecessor, class: :Assertion

  many_to_one :created_user, class: :User
  plugin :context, created_user: :user
end

class Assertion < Variable
  set_context_map created_user: :user

  one_to_many :predecessors, class: AssertionRelation, reciprocal: :successor
  one_to_many :successors, class: AssertionRelation, reciprocal: :predecessor
end

class ProductClass < Assertion

end

class Collection < Assertion

end

class InstanceCollection < Collection

end

class Product < Collection

end


class AbstractPropertyValue < Variable
  private
  attr_writer :previous
  public
  def persisted?
    !@previous.nil? || super
  end

  def new(new_values = {})
    vals = values.dup
    vals.delete(:created_at)
    vals.merge!(new_values)

    o = self.class.new(new_values)
    o.send(:set_restricted, { link_key => values[link_key] }, [link_key])
    o.send('previous=', self)
    o.changed_columns.clear
    yield o if block_given?
    o
  end

  def create(values = {}, &block)
    new(values, &block).save
  end
end

class AbstractProperty < AbstractPropertyValue
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale

  def self.set_value_class(key)
    @value_class = key

    one_to_many :property_values, class: key, key: :property_id, primary_key: :id
  end
  cattr_reader :value_class

end
class AbstractSingleProperty < AbstractProperty
end
class AbstractSetProperty < AbstractProperty
end
class AbstractValue < AbstractPropertyValue
end

class ValueNatural < AbstractValue
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale
end
class PropertySingleNatural < AbstractSingleProperty
  set_value_class ValueNatural
end
class PropertySetNatural < AbstractSetProperty
  set_value_class ValueNatural
end

class ValueString < AbstractValue
  set_primary_key [:id, :created_at]
  set_context_map created_user: :user
end
class PropertySingleString < AbstractSingleProperty
  set_value_class ValueString
end
class PropertySetString < AbstractSetProperty
  set_value_class ValueString
end

class ValueFloat < AbstractValue
  set_primary_key [:id, :created_at]
end
class PropertySingleFloat < AbstractSingleProperty
  set_value_class ValueFloat
end

class ValueInteger < AbstractValue
  set_primary_key [:id, :created_at]
end
class PropertySingleInteger < AbstractSingleProperty
  set_value_class ValueInteger
end

class Instance < Variable

end

# Pricing is a specific property value
class AbstractPricing < AbstractValue

end

class PriceSingle < AbstractPricing

end

class PriceDiscrete < AbstractPricing
end
class PriceReplaceDiscrete < PriceDiscrete
end
class PriceAddDiscrete < PriceDiscrete
end
class PriceMultiplyDiscrete < PriceDiscrete
end

class PriceDiscreteBreak < Sequel::Model

end

class PriceInput < Sequel::Model

end



# Variable
# |- PropertyValue (versioned)
# |  |- Value : no children (by Variable Inherit)
# |  |- Property : children (by Variable Inherit)
# |- Instance
# |- Pricing (mix with Value)
# |- Collection
# |  |- Product
# |  |- InstanceCollection