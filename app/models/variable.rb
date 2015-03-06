class Variable < Sequel::Model
  type_map = {
      PropertySingleNatural: :properties,
      PropertySingleString: nil,
      PropertySingleFloat: nil,
      PropertySingleInteger: nil,
      PropertySingleNull: nil,
      PropertySetNatural: [nil, 1 * 2**8],
      PropertySetString: nil,

      ValueNull: [:values, 8 * 2**8],
      ValueNatural: :value_naturals,
      ValueString: :value_strings,
      ValueFloat: :value_floats,
      ValueInteger: :value_integers,

      PriceSingle: [:value_integers, 9 * 2**8],
      PriceReplaceDiscrete: :functions,
      PriceAddDiscrete: nil,
      PriceMultiplyDiscrete: nil,

      User: [:users, 16 * 2**8],
      Assertion: :assertions,
      Collection: nil,
      InstanceCollection: nil,
      ProductClass: nil,
      Product: nil,

      Instance: [:value_integers, 17 * 2**8 + 1],
      #Variable: :variables,

      PropertyValue: :variables,
      Property: :properties,
      PropertySingle: nil,
      PropertySet: nil,
      Value: :values,
      Pricing: nil,
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

  plugin :context, created_user: :user, locale: :locale

  plugin :pg_array_associations
  many_to_pg_array :provides, class: :Predicate, key: :dependent_ids

  def implies(*list)
    list.flatten.each do |var|
      var.predicate_on(self)
    end
  end
end


class Instance < Variable

end
