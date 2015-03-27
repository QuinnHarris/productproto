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
    puts "  + #{type}: #{params.inspect} => #{@id}"
    m
  end
end

class VariableDescription < ModelDescription
  def initialize(value, id = nil)
    if value.is_a?(Variable)
      @model = value
      @id = value.id
      @value = value.value
    else
      @value = value
      @id = id
    end
    raise "NO VALUE" if @value.nil?
    @provides = []
  end
  attr_reader :provides

  def value
    return @value unless @value.nil?
    @value = model.value
  end

  def inspect
    "\#<#{self.class} @id=#{@id} @value=#{@value} @type=#{type}>"
  end

  def marshal_dump
    [@id, value]
  end

  def marshal_load(array)
    @id, @value, *remain = array
    raise "NO VALUE: #{@id}" if @value.nil?
    remain
  end

  def add_provide(predicate)
    #@provides << predicate
  end

  def create(params = {})
    super(params.merge(value: @value))
  end
end

Property
class PropertyDesc < VariableDescription
  def initialize(value)
    super value
    raise "Must have ID" unless @id
    raise "Must be a Property: #{value.inspect}" unless value.is_a?(Property)
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

  def add_value(vd)
    @value_map[vd.value] = vd
  end

  def get_value(value)
    value = type.value_class.value_transform(value)
    desc = @value_map[value]
    return desc if desc
    @value_map[value] = ValueDesc.new(self, value)
  end

  def values
    @value_map.values
  end
end

class ValueDesc < VariableDescription
  def initialize(property, value, id = nil)
    @property = property
    unless type.value_valid?(value)
      raise "Invalid Value: #{type.class}: #{value.inspect}"
    end

    super value, id
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

  def add_predicate(predicate)
    @predicates[predicate.dependents] = predicate
  end

  def set_predicate(dependents)
    dependents = Set.new(dependents)
    if predicate = @predicates[dependents]
      predicate.touch!
    else
      add_predicate(PredicateDesc.new(self, dependents))
    end
  end
end

class FunctionDiscreteDesc < ValueDesc
  def type; FunctionDiscrete; end

end

class AssertionDesc < VariableDescription

end


class ProductDesc < AssertionDesc
  def initialize(data, value, id = nil)
    super value, id
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


class PredicateDesc < ModelDescription
  def initialize(value, dependents, id = nil)
    raise "Must have dependents" if dependents.empty?
    dependents.each  do |d|
      raise "Dependent must be variable: #{d}" unless d.is_a?(VariableDescription)
      d.add_provide(self)
    end
    @dependents = dependents.is_a?(Set) ? dependents : Set.new(dependents)
    @value = value
    @id = id
  end
  attr_reader :dependents, :value, :touched
  def touch!
    @touched = true unless new?
    self
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
    { assertion_dependent_ids: assertion_ids.sort, value_dependent_ids: value_ids.sort }
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
    if cache_exists?
      cache_load
    else
      @changed = true
      db_load
    end
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

  private def add_property(property)
    @property_id_map[property.id] = property
    if val = @property_name_map[property.value]
      @property_name_map[property.value] = Array(val) + [property]
    else
      @property_name_map[property.value] = property
    end
  end

  def marshal_load(hash)
    hash[:properties].each do |property|
      add_property(property)
    end
    hash[:products].each do |product|
      product.instance_variable_set('@d', self)
      @product_name_map[product.value] = product
    end
    @dirty = hash[:dirty]
  end

  private def stream_group_by(dataset, key_column)
    current_id = nil
    current_set = []
    dataset.order(key_column).stream.each do |hash|
      if hash[key_column] == current_id
        current_set << hash
      else
        yield current_id, current_set if current_id
        current_id = hash[key_column]
        current_set = [hash]
      end
    end
    yield current_id, current_set if current_id
  end

  def db_load
    def id_to_class(id, type)
      klass_s = Variable.cti_model_map[id]
      klass = Variable.send(:constantize, klass_s)
      raise "Must be a #{type}: #{klass}" unless klass.ancestors.include?(type)
      klass
    end

    def row_to_table(hash)
      klass_s = Variable.cti_model_map[hash[:type_id]]
      Variable.cti_table_map[klass_s]
    end

    puts "Loading from Database:"

    Variable.db.transaction do
      print "  Assertions: "
      assertion_ds = AssertionRelation.decend_dataset([@supplier.id])
      assertion_table = :assert_decend
      Variable.db.create_table assertion_table, temp: true, on_commit: :drop, as: assertion_ds

      variable_map = {}
      Variable.db[assertion_table].join(:assertions, :id => :id).stream.each do |assert_hash|
        klass = id_to_class(assert_hash[:type_id], Assertion)
        next if klass == Supplier and assert_hash[:id] == @supplier.id
        raise "Unexpected class: #{klass}" unless klass == Product

        pd = ProductDesc.new(self, assert_hash[:value], assert_hash[:id])
        variable_map[pd.id] = pd
        @product_name_map[pd.value] = pd
      end

      puts @product_name_map.length
      if @product_name_map.empty?
        puts  "    NO ASSERTIONS"
        return
      end


      predicate_map = {}
      table_map = {}

      print "  Predicates: "
      Predicate.assert_dataset(assertion_table).stream.each do |value_hash|
        table_s = row_to_table(value_hash)

        id = value_hash[:value_id]

        unless predicate_map[id]
          (table_map[table_s] ||= {})[id] = value_hash[:type_id]
          predicate_map[id] = []
        end

        predicate_map[id] << [value_hash[:id],
                              value_hash[:assertion_dependent_ids] + value_hash[:value_dependent_ids]]
      end

      puts predicate_map.length
      if predicate_map.empty?
        puts "    NO PREDICATES"
        return
      end


      function_break_map = {}
      function_map = table_map[:functions]
      print "  Function Breaks: "

      ds = FunctionDiscreteBreak.dataset.naked!
               .where(:function_id => function_map.keys)
               .select_append(
                   Sequel.function(:row_number)
                       .over(partition: [:function_id, :minimums],
                             order: Sequel.desc(:created_at)))
               .from_self.where(:value => nil).invert.where(:row_number => 1)

      stream_group_by(ds, :function_id) do |current_id, current_set|
        # Similar to model function.rb
        function_break_map[current_id] = current_set.each_with_object({}) do |brk, hash|
          hash[brk[:minimums].to_a] = brk[:value]
        end
      end if function_map
      puts function_break_map.length


      value_list = []
      table_map.each do |table_name, sub_map|
        print "  Value (#{table_name}): "
        last_length = value_list.length
        ds = Value.db.from(table_name).join(:values, :id => :id)
                 .where(:values__id => sub_map.keys)

        unless table_name == :functions
            ds = ds.select_append(
                Sequel.function(:row_number)
                    .over(partition: [:values__id, :property_id],
                          order: Sequel.desc(:created_at)))
                     .from_self.where(:row_number => 1)
        end

        ds.stream.each do |sub_hash|
          @property_id_map[sub_hash[:property_id]] = true

          if table_name == :functions
            value = function_break_map[sub_hash[:id]]
            raise "No Function Value: #{sub_hash[:id]}" unless value
          else
            value = sub_hash[:value]
          end

          vs = [sub_hash[:id], sub_hash[:property_id], sub_map[sub_hash[:id]], value]
          value_list << vs
        end
        puts value_list.length - last_length
      end
      table_map = nil

      print "  Properties: "
      Property.dataset.where(:variables__id => @property_id_map.keys).stream.each do |property|
        add_property PropertyDesc.new(property)
      end
      puts @property_id_map.length

      puts "  Assembling"
      value_list.map do |value_id, property_id, type_id, value|
        property = @property_id_map[property_id]
        value_class = id_to_class(type_id, Value)
        raise "Properby value mismatch" unless property.type.value_class == value_class
        variable_map[value_id] = vd = ValueDesc.new(property, value, value_id)
        property.add_value vd
      end.each do |vd|
        predicate_map[vd.id].each do |predicate_id, list|
          dependents = list.map { |i| variable_map[i] }
          raise "Empty Dependent" if dependents.empty?
          raise "Dependent not mapped: #{list} => #{dependents} " if dependents.include?(nil)
          vd.add_predicate PredicateDesc.new(vd, dependents, predicate_id)
        end
      end

    end
  end

  def cache_file
    Rails.root.join('import', 'cache', "#{supplier.value}.database").to_s
  end

  def cache_exists?
    File.exists?(cache_file)
  end

  def cache_load
    print "Loading from Cache #{cache_file}: "
    File.open(cache_file) { |f| marshal_load(Marshal.load(f)) }
    puts "DONE"
  end

  def cache_write
    # Use temporary file incase process is terminated during write
    print "Writing Cache to #{cache_file}: "
    @changed = nil
    File.open(cache_file+'.temp','w') { |f| Marshal.dump(marshal_dump, f) }
    File.rename(cache_file+'.temp', cache_file)
    puts "DONE"
  end

  def get_product(name)
    #if p = supplier.predecessors_dataset.find(name: id)
    #  raise "Expected Product" unless p.is_a?(Product)
    #  return p
    #end
    @dirty = true
    desc = @product_name_map[name]
    return desc if desc
    @product_name_map[name] = ProductDesc.new(self, name)
  end

  private def find_properties(name, type = nil)
    props = Array(@property_name_map[name])
    if type
      klass = Property.class_get(type)
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
    add_property prop
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

      unused_values = []
      properties = @property_id_map.values
      properties.each do |pd|
        unused = pd.values.map do |vd|
          next unless vd.new?
          next vd if vd.predicates.empty?
          change = true
          vd.create
          nil
        end.compact
        unused_values << [pd, unused] unless unused.empty?
      end
      unless unused_values.empty?
        puts "  * Values Not Used:"
        unused_values.each do |pd, unused|
          puts "    #{pd.value} (#{pd.type.property_name}): #{unused.map { |vd| vd.value}.join(', ')}"
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
            puts "REMOVE: #{pred}"
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