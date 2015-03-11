Value

class Property < PropertyValue
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale

  def self.set_value_class(key)
    @value_class = key

    one_to_many :property_values, class: key, key: :property_id, primary_key: :id
  end
  def self.value_class; @value_class; end
end
class PropertySingle < Property
end
class PropertySet < Property
end

class PropertySingleNull < Property
  set_value_class ValueNull
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
class PropertySingleBoolean < PropertySingle
  set_value_class ValueBoolean
end
