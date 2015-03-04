require 'rails_helper'

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
    product = Product.create #(locale: @locale, created_user: @user)
    expect(product).to be_an_instance_of(Product)

    sku_prop = PropertySingleString.create(name: 'SKU')
    sku_val = sku_prop.add_property_value(value: '123')

    sku_val.predicate_on(product)

    color_prop = PropertySetNatural.create(name: 'Color')
    %w(Red Green Blue).each do |color|
      color_val = color_prop.add_property_value(value: color)
      product.implies(color_val)
    end

  end
end
