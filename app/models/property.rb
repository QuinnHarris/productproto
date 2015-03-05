Value

class Property < PropertyValue
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale

  def self.set_value_class(key)
    @value_class = key

    one_to_many :property_values, class: key, key: :property_id, primary_key: :id
  end
  cattr_reader :value_class

end
class PropertySingle < Property
end
class PropertySet < Property
end

# Natural
class PropertySingleNatural < PropertySingle
  set_value_class ValueNatural
end
class PropertySetNatural < PropertySet
  set_value_class ValueNatural
end

# String
class PropertySingleString < PropertySingle
  set_value_class ValueString
end
class PropertySetString < PropertySet
  set_value_class ValueString
end

# Numbers
class PropertySingleFloat < PropertySingle
  set_value_class ValueFloat
end
class PropertySingleInteger < PropertySingle
  set_value_class ValueInteger
end
