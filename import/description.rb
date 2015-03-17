class ModelDescription
  def initialize
    raise "Must override"
  end

  #attr_reader :id
  def id
    raise "No ID" unless @id
    @id
  end

  def new?
    !@id
  end

  def model
    @model ||= type.find(Sequel.qualify(type.table_name, :id) => id)
  end

  def marshal_dump
    [@id]
  end

  def marshal_load(array)
    @id, *remain = array
    remain
  end

  private
  def create(params)
    @model = type.create(params)
    @id = model.id
    puts "+ #{type}: #{params.inspect} => #{@id}"
    model
  end
end

class VariableDescription < ModelDescription
  def initialize(value)
    if value.is_a?(Variable)
      @model = value
      @id = value.id
      @value = value.value
    else
      @value = value
    end
    raise "NO VALUE" unless @value
  end

  def value
    @value ||= model.value
  end

  def inspect
    "\#<#{self.class} @id=#{@id} @value=#{@value}>"
  end

  def marshal_dump
    [@id, value]
  end

  def marshal_load(array)
    @id, @value, *remain = array
    raise "NO VALUE" unless @value
    remain
  end

  def create(params = {})
    super(params.merge(value: value))
  end
end

Property
class PropertyDesc < VariableDescription
  def initialize(value)
    super value
    raise "Must have ID" unless @id
    @type = value.class
    @value_map = {}
  end
  attr_reader :type

  def marshal_dump
    super + [@type, @value_map]
  end

  def marshal_load(array)
    @type, @value_map, = super array
  end

  def get_value(value)
    desc = @value_map[value]
    return desc if desc
    @value_map[value] = ValueDesc.new(self, value)
  end

  def values
    @value_map.values
  end
end

class ProductDesc < VariableDescription
  def initialize(data, value)
    super value
    @d = data
  end
  attr_reader :d
  def supplier; d.supplier; end
  def type; Product; end

  def create
    model = super
    AssertionRelation.create(successor: supplier, predecessor: model)
  end

  def set_value(property, value)
    pd = d.find_property(property)
    vd = pd.get_value(value)
    vd.set_predicate([self])
    vd
  end

  def set_values(property, values)
    map = {}
    pd = d.find_property(property)
    values.each do |value|
      vd = pd.get_value(value)
      vd.set_predicate([self])
      map[value] = vd
    end
    map
  end

  def set_implies(*values)
    values.flatten.each do |value|
      value.set_predicate([self])
    end
  end
end

class ValueDesc < VariableDescription
  def initialize(property, value)
    super value
    @property = property
    @predicates = {}
  end
  attr_reader :property

  def predicates
    @predicates.values
  end

  def predicates_delete_if
    @predicates.delete_if do |dep, pred|
      yield pred
    end
  end

  def type
    property.type.value_class
  end

  def inspect
    "#:<ValueDesc @id=#{@id} @value=#{@value} @property=#{@property.value} @predicates.length=#{@predicates.length}"
  end

  def marshal_dump
    super + [@property, @predicates]
  end

  def marshal_load(array)
    @property, @predicates, = super array
  end

  def create
    super(property_id: property.id)
  end

  def set_predicate(dependents)
    dependents = Set.new(dependents)
    predicate = @predicates[dependents]
    if predicate
      predicate.touch!
    else
      predicate = PredicateDesc.new(dependents)
      @predicates[dependents] = predicate
    end
    predicate
  end
end


class PredicateDesc < ModelDescription
  def initialize(dependents)
    raise "Must have dependents" if dependents.empty?
    dependents.each {|d| raise "Dependent must be variable" unless d.is_a?(VariableDescription)}
    @dependents = dependents.is_a?(Set) ? dependents : Set.new(dependents)
  end
  attr_reader :dependents, :touched
  def touch!
    @touched = true unless new?
  end

  def type; Predicate; end

  def marshal_dump
    super + [@dependents]
  end

  def marshal_load(array)
    @dependents, = super array
  end

  def create(vd)
    super(value_id: vd.id,
          dependent_ids: dependents.map { |d| d.id } )
  end

  # Change to use remove on existing predicate, consider permissions and context
  def remove(vd)
    super(value_id: vd.id,
          dependent_ids: dependents.map { |d| d.id },
          deleted: true )
  end
end

class DataDescription
  def initialize(supplier)
    @supplier = supplier
    # Initialize data from @supplier
    @property_id_map = {}
    @property_name_map = {}
    @product_name_map = {}
    cache_read if cache_exists?
  end
  attr_reader :supplier

  def dirty?; @dirty; end

  def marshal_dump
    {
        dirty: true,
        properties: @property_id_map.values,
        products: @product_name_map.values,
    }
  end

  def marshal_load(hash)
    hash[:properties].each do |property|
      @property_id_map[property.id] = property
      @property_name_map[property.value] = property
    end
    hash[:products].each do |product|
      product.instance_variable_set('@d', self)
      @product_name_map[product.value] = product
    end
  end

  def cache_file
    Rails.root.join('import', 'cache', "#{supplier.value}.database").to_s
  end

  def cache_exists?
    File.exists?(cache_file)
  end

  def cache_read
    print "Reading Cache from #{cache_file}: "
    File.open(cache_file) { |f| marshal_load(Marshal.load(f)) }
    puts "DONE"
  end

  def cache_write
    # Use temporary file incase process is terminated during write
    print "Writing Cache to #{cache_file}:"
    File.open(cache_file+'.temp','w') { |f| Marshal.dump(marshal_dump, f) }
    File.rename(cache_file+'.temp', cache_file)
    puts "DONE"
  end

  def find_property(name)
    @property_name_map[name] || raise("Can't find property: #{name}")
  end

  def get_product(id)
    #if p = supplier.predecessors_dataset.find(name: id)
    #  raise "Expected Product" unless p.is_a?(Product)
    #  return p
    #end
    @dirty = true
    desc = @product_name_map[id]
    return desc if desc
    @product_name_map[id] = ProductDesc.new(self, id)
  end

  def apply_property(name, type = nil, set = false)
    klass_s = "Property#{set ? 'Set' : 'Single'}#{type.to_s.capitalize}"
    klass = Property.const_get(klass_s)
    desc = @property_name_map[name]
    return if desc

    @dirty = true
    if existing = model = Property.find(value: name)
      raise "Classes do not match" unless model.is_a?(klass)
    else
      model = klass.create(value: name)
    end
    desc = PropertyDesc.new(model)
    @property_id_map[model.id] = desc
    @property_name_map[name] = desc
    existing ? nil : desc
  end

  def apply_data
    Sequel::Model.db.transaction do
      @product_name_map.values.each do |prod|
        prod.create if prod.new?
      end

      properties = @property_id_map.values
      properties.each do |pd|
        pd.values.each do |vd|
          vd.create if vd.new?
        end
      end

      properties.each do |pd|
        pd.values.each do |vd|
          vd.predicates_delete_if do |pred|
            next if pred.touched
            if pred.new?
              pred.create(vd)
              next
            end
            puts "REMOVE"
            # Only existing untouched left (must be removed)
            pred.remove(vd)
            true
          end
        end
      end

      @dirty = true
      cache_write
    end
  end
end