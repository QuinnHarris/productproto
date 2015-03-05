require 'rails_helper'

Property

RSpec.describe Variable, type: :model do
  before do
    #@locale = Locale.find(id: 1)
    user = User.find(users__id: 1)
    DBContext.apply_open!(user: user)
  end
  after do
    DBContext.apply_close!
  end
  it "can create a product" do
    brand_class = ProductClass.create
    brand_prop = PropertySingleString.create(name: 'Brand')
    brand_val = brand_prop.add_property_value(value: 'Gilden')
    brand_class.implies(brand_val)

    product = Product.create
    expect(product).to be_an_instance_of(Product)

    AssertionRelation.create(predecessor: brand_class, successor: product)

    sku_prop = PropertySingleString.create(name: 'SKU')
    sku_val = sku_prop.add_property_value(value: '123')

    sku_val.predicate_on(product)

    color_prop = PropertySetNatural.create(name: 'Color')
    %w(Red Green Blue).each do |color|
      color_val = color_prop.add_property_value(value: color)
      product.implies(color_val)
    end

    # Enumerate table
    # id,type,access,dependent_ids,deleted
    # product.decendents set of eager Predicate
  end
end
