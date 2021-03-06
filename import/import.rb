require File.expand_path('../../config/environment',  __FILE__)
require_relative 'description'

class ValidateError < StandardError
  def initialize(aspect, value = nil)
    @aspect, @value = aspect, value
  end
  attr_reader :aspect, :value

  def mark_duplicate!
    @aspect = "DUP #{@aspect}"
  end

  def to_s
    "#{aspect}: #{value}"
  end
end

Assertion # To load Supplier model

class GenericImport
  def self.supplier_name
    raise "Class name must end in Import" unless /^(\w+)Import$/ =~ name
    $1
  end
  def self.create
    n = supplier_name
    m = nil
    Supplier.db.transaction do
      raise "Already Exists: #{n}" if Supplier.find(value: n)
      # FIX !!!
      user = User.find(users__id: 1)
      raise "No user" unless user

      m = Supplier.create(value: n, created_user_id: user.id)

      #o = self.new
      #o.apply_schema
      #o
    end
    m
  end

  def initialize
    supplier = Supplier.find(value: self.class.supplier_name)
    unless supplier
      puts "!!! CREATING SUPPLIER: #{self.class.supplier_name}"
      supplier = self.class.create
    end
    @d = DataDescription.new supplier

    # Fix !!!
    user = User.find(users__id: 1)
    raise "No user" unless user
    DBContext.apply_open!(user: user)

    @invalid_prods = {}
    @warning_prods = {}

    @invalid_values = {}
    @warning_values = {}
  end
  attr_reader :d

  def add_error(boom, id)
    puts "  + #{id}: #{boom}"  unless ARGV.include?('nowarn')
    @invalid_prods[boom.aspect] = (@invalid_prods[boom.aspect] || []) + [id]
    @invalid_values[boom.aspect] ||= (h = {}; h.default = 0; h)
    @invalid_values[boom.aspect][boom.value] += 1
  end

  def add_warning(boom, id = @supplier_num)
    puts "  * #{id}: #{boom}"  unless ARGV.include?('nowarn')
    @warning_prods[boom.aspect] = (@warning_prods[boom.aspect] || []) + [id]
    @warning_values[boom.aspect] ||= (h = {}; h.default = 0; h)
    @warning_values[boom.aspect][boom.value] += 1
  end

  def warning(aspect, description = nil, id = @supplier_num)
    add_warning(ValidateError.new(aspect, description), id)
  end

  def apply_data
    #if d.dirty?
    #  puts "Cache Dirty!!!"
    #else
      puts "Define Data:"
      define_data
      #d.cache_write
    #end
    puts "Apply Data:"
    d.apply_data
  end

  def define_schema
    {
        product_code: :string_single,
        item_code: :string_single,
        name: :natural_single,
        size: :string_set,
        color: :natural_set,
        price: [:function_discrete, :integer_single],
        price_retail: :integer_single,
    }.each do |prop, type_list|
      Array(type_list).each do |type|
        if d.apply_property(prop.to_s, type)
          puts "#{prop} (#{type})"
        end
      end
    end
  end

  def apply_schema
    Supplier.db.transaction do
      define_schema
      d.cache_write if d.changed?
    end
  end

  def apply
    puts "Define Schema:"
    apply_schema
    apply_data
  end
end
