class Source < Sequel::Model(:sales__source)
  one_to_many :business_sources

  def self.get(name)
    o = self.where(name: name).first
    return o if o
    self.create(name: name)
  end
end
