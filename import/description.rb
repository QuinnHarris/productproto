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
  # Through away model because we are currently not using it
  def create(params)
    m = type.create(params)
    @id = m.id
    puts "+ #{type}: #{params.inspect} => #{@id}"
    m
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
    "\#<#{self.class} @id=#{@id} @value=#{@value} @type=#{type}>"
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

class AssertionDesc < VariableDescription

end

class ProductDesc < AssertionDesc
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

class FunctionDiscreteDesc < ValueDesc
  def type; FunctionDiscrete; end


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

  def dependent_split_ids
    assertion_ids = []
    value_ids = []
    dependents.each do |dep|
      if dep.is_a?(AssertionDesc)
        assertion_ids << dep.id
      elsif dep.is_a?(ValueDesc)
        value_ids << dep.id
      else
        raise "Unknown dependent: #{dep}"
      end
    end
    { assertion_dependent_ids: assertion_ids, value_dependent_ids: value_ids }
  end

  def create(vd, deleted = false)
    super(dependent_split_ids.merge(value_id: vd.id, deleted: deleted))
  end

  # Change to use remove on existing predicate, consider permissions and context
  def remove(vd)
    create(vd, true)
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
  def changed?; @changed; end

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
      if val = @property_name_map[property.value]
        @property_name_map[property.value] = Array(val) + [property]
      else
        @property_name_map[property.value] = property
      end
    end
    hash[:products].each do |product|
      product.instance_variable_set('@d', self)
      @product_name_map[product.value] = product
    end
  end

  def db_read
    
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
    @changed = nil
    File.open(cache_file+'.temp','w') { |f| Marshal.dump(marshal_dump, f) }
    File.rename(cache_file+'.temp', cache_file)
    puts "DONE"
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

  private def find_properties(name, type = nil)
    props = Array(@property_name_map[name])
    if type
      klass_s = "Property#{type.to_s.camelize}"
      klass = Property.const_get(klass_s)
      raise "Unknown class: #{klass_s}" unless klass
      [props.find_all { |p| p.type == klass }, klass]
    else
      [props]
    end
  end

  def find_property(name, type = nil)
    props, klass = find_properties(name, type)
    raise "Can't find property: #{name} #{type}" if props.empty?
    raise "Multiple property canidates: #{props}" if props.length > 1
    props.first
  end

  def apply_property(name, type)
    props, klass = find_properties(name, type)
    return unless props.empty?

    @changed = true
    # !!!! Table inheritance should be fixed to not need find_all
    models = klass.where(value: name).all.find_all { |m| m.is_a?(klass) }
    raise "Multiple models" if models.length > 1
    existing = model = models.first
    model = klass.create(value: name) unless model
    prop = PropertyDesc.new(model)
    @property_id_map[model.id] = prop
    if val = @property_name_map[name]
      @property_name_map[name] = Array(val) + [prop]
    else
      @property_name_map[name] = prop
    end
    existing ? nil : prop
  end

  def apply_data
    Sequel::Model.db.transaction do
      change = false
      @product_name_map.values.each do |prod|
        next unless prod.new?
        change = true
        prod.create
      end

      properties = @property_id_map.values
      properties.each do |pd|
        pd.values.each do |vd|
          next unless vd.new?
          change = true
          vd.create
        end
      end

      properties.each do |pd|
        pd.values.each do |vd|
          vd.predicates_delete_if do |pred|
            next if pred.touched
            change = true
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

      @dirty = false
      cache_write if change
    end
  end
end