# Pricing is a specific property value
class Function < Value
  many_to_many :scope_properties, class: Property, table: :function_scopes
  one_to_many :inputs, class: :FunctionInput
end

class FunctionInput < Sequel::Model
end


class FunctionDiscrete < Function
  one_to_many :breaks, class: :FunctionDiscreteBreak, order: [:argument, :minimum]

  # Set Price
  def set(hash)
    hash.each do |input, value|
      Array(input).each_with_index do |min, i|
        add_break(argument: i, minimum: min, value: value)
      end
    end
  end

  def get
    breaks.each_with_object({}) do |brk, hash|
      (hash[brk.value] ||= [])[brk.argument] = brk.minimum
    end.each_with_object({}) do |(val, ary), hash|
      hash[ary] = val
    end
  end
end

class FunctionDiscreteBreak < Sequel::Model
  many_to_one :functions, class: :FunctionDiscrete
end

class FunctionDiscreteReplace < FunctionDiscrete
end
class FunctionDiscreteAdd < FunctionDiscrete
end
class FunctionDiscreteMultiply < FunctionDiscrete
end
