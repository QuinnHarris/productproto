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
      Collection: nil,
      InstanceCollection: nil,
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


  def predicate_on(list, user)
    Predicate.create(self, list, user)
  end

  def implies(var, user)
    var.predicate_on(self, user)
  end
end

class Predicate < Sequel::Model
  many_to_one :variable
  many_to_many :variables, class: Variable, join_table: :predicates_and
  many_to_one :created_user, class: :User

  #private :new
  def self.create(dst, srcs, user, deleted = false)
    db.transaction do
      p = super(variable: dst, created_user: user, deleted: deleted)
      Array(srcs).flatten.each do |o|
        p.add_variable(o)
      end
    end
  end
end

class Assertion < Variable

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