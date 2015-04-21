class Variable < Sequel::Model
  type_map = {
      PropertyNaturalSingle: nil,
      PropertyStringSingle: nil,
      PropertyFloatSingle: nil,
      PropertyIntegerSingle: nil,
      PropertyBoolean: nil,
      PropertyNull: nil,

      PropertyNaturalSet: 1 * 2**8,
      PropertyStringSet: nil,

      PropertyFunctionDiscrete: 2 * 2**8,

      ValueNull: 8 * 2**8,
      ValueNatural: nil,
      ValueString: nil,
      ValueFloat: nil,
      ValueInteger: nil,
      ValueBoolean: nil,

      FunctionDiscrete: 9 * 2**8,
      FunctionDiscreteReplace: nil,
      FunctionDiscreteAdd: nil,
      FunctionDiscreteMultiply: nil,

      User: 16 * 2**8,
      Assertion: nil,
      Collection: nil,
      InstanceCollection: nil,
      Supplier: nil,
      ProductClass: nil,
      Product: nil,
      Organization: nil,
      ValueAdder: nil,

      Instance: 17 * 2**8 + 1, # ValueInteger table

      PropertyValue: nil,
      Property: nil,
      PropertySingle: nil,
      PropertySet: nil,
      PropertyFunction: nil,
      Value: nil,
      Function: nil,
  }

  model_map = {}
  index = 0
  type_map.each do |c, i|
    index = i || index
    model_map[index] = c
    index += 1
  end
  #plugin :insert_returning_select
  plugin :hybrid_table_inheritance, key: :type_id, model_map: model_map, eager_load: true

  many_to_one :created_user, class: :User
  many_to_one :locale

  plugin :context, created_user: :user, locale: :locale

  plugin :pg_array_associations
  many_to_pg_array :provides, class: :Predicate, key: :dependent_ids

  def implies(*list)
    list.flatten.each do |var|
      var.predicate_on(self)
    end
  end

  def self.update_types
    db.transaction do
      ds = db[:variable_types]
      existing = {}
      ds.all.each { |hash| existing[hash[:id]] = hash }
      cti_model_map.each do |id, type|
        table = cti_table_map[type]
        hash = { id: id, type: type.to_s, table: table.to_s }
        if prev = existing[id]
          ds.where(id: id).update(hash.except(:id)) unless prev == hash
        else
          ds.insert(hash)
        end
      end
    end

  end
end
