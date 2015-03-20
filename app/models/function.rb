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
  def value=(hash)
    db.transaction do
      save if new? # Need ID for foreign key reference
      hash.each do |input, value|
        Array(input).each_with_index do |min, i|
          brk = FunctionDiscreteBreak.new(function: self, value: value)
          brk.send(:set_restricted, { argument: i, minimum: min }, [:argument, :minimum])
          brk.save
        end
      end
    end
  end

  # Similar to import description.rb
  def value
    breaks.each_with_object({}) do |brk, hash|
      (hash[brk.value] ||= [])[brk.argument] = brk.minimum
    end.each_with_object({}) do |(val, ary), hash|
      hash[ary] = val
    end
  end

  def self.value_valid?(value)
    return false unless value.is_a?(Hash)
    value.each do |list, value|
      return false unless value.is_a?(Fixnum)
      return false unless list.is_a?(Array)
      list.each { |i| return false unless i.is_a?(Fixnum) }
    end
    true
  end
end

class FunctionDiscreteBreak < Sequel::Model
  plugin :context, created_user: :user

  many_to_one :function, class: :FunctionDiscrete

  many_to_one :created_user, class: :User
end

class FunctionDiscreteReplace < FunctionDiscrete
end
class FunctionDiscreteAdd < FunctionDiscrete
end
class FunctionDiscreteMultiply < FunctionDiscrete
end
