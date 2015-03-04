require 'rails_helper'

RSpec.describe Variable, type: :model do
  before do
    @locale = Locale.find(id: 1)
    @user = User.find(users__id: 1)
  end
  it "can create a product" do
    product = Product.create(locale: @locale, created_user: @user)
    expect(product).to be_an_instance_of(Product)

    sku_prop = PropertySingleString.create(locale: @locale, created_user: @user, name: 'SKU')
    sku_val = sku_prop.add_property_value(created_user: @user, value: '123')

    sku_val.predicate_on(product, @user)

    color_prop = PropertySetNatural.create(locale: @locale, created_user: @user, name: 'Color')
    %w(Red Green Blue).each do |color|
      color_val = color_prop.add_property_value(locale: @locale, created_user: @user, value: color)
      product.implies(color_val, @user)
    end

  end
end
