class Business < Sequel::Model
  one_to_many :business_sources
  one_to_many :phones, class: :BusinessPhone
  one_to_many :emails, class: :BusinessEmail
  one_to_many :addresses, class: :BusinessAddress


  # Values
  # Name, Website, Address, phone, email
  def self.insert_update(source, values)
    bus = Business.where(name: values[:name], website: values[:website]).first
    return bus if bus && bus.phones_dataset.where(value: values[:phone]).first
    db.transaction do
      bus = Business.create(name: values[:name], website: values[:website])
      Array(values[:phones]).each do |phone|
        bus.add_phone(type: 'Primary', value: phone)
      end
      bus.add_address(values[:address])
      BusinessSource.create(business: bus, source: source, reference: values[:reference])
    end unless bus
    bus
  end
end
