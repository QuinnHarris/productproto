class BusinessPhone < Sequel::Model(:sales__business_phones)
  many_to_one :business

  def before_save
    self.number = self.value.gsub(/[^0-9]/, '').to_i
  end
end
