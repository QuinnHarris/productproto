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
    brand_prop = PropertySingleString.create(value: 'Brand')
    brand_val = brand_prop.add_property_value(value: 'Gildan')
    brand_class.implies(brand_val)

    product_class = ProductClass.create
    AssertionRelation.create(predecessor: brand_class, successor: product_class)

    color_prop = PropertySingleNatural.create(value: 'Color')
    %w(Red Green Blue).each do |color|
      color_val = color_prop.add_property_value(value: color)
      product_class.implies(color_val)
    end

    sku_prop = PropertySingleString.create(value: 'SKU')
    sku_val = sku_prop.add_property_value(value: '2000')
    sku_val.predicate_on(product_class)

    size_class_prop = PropertySingleNatural.create(value: 'Size Class')
    gender_prop = PropertySetNatural.create(value: 'Gender')
    gender_male, gender_female = %w(Male Female).map do |gender|
      gender_prop.add_property_value(value: gender)
    end
    size_prop = PropertySingleString.create(value: 'Size')
    size_list = %w(S M L XL 2XL 3XL 4XL 5XL).map do |size|
      size_prop.add_property_value(value: size)
    end
    size_wc_prop = PropertySingleNull.create(value: 'Size & Class')


    # Adult
    product_adult = Product.create
    AssertionRelation.create(predecessor: product_class, successor: product_adult)

    size_class_val = size_class_prop.add_property_value(value: 'Adult')
    size_class_val.implies gender_male, gender_female
    product_adult.implies size_class_val

    size_list.each do |size_val|
      size_wc_val = size_wc_prop.add_property_value({})
      size_wc_val.predicate_on size_class_val, size_val
      product_adult.implies size_wc_val
    end


    # Ladies
    product_ladies = Product.create
    product_ladies.implies sku_prop.add_property_value(value: 'L')

    AssertionRelation.create(predecessor: product_class, successor: product_ladies)
    size_class_val = size_class_prop.add_property_value(value: 'Ladies')
    size_class_val.implies gender_female
    product_ladies.implies size_class_val

    size_list[0..-4].each do |size_val|
      size_wc_val = size_wc_prop.add_property_value({})
      size_wc_val.predicate_on size_class_val, size_val
      product_adult.implies size_wc_val
    end




    # Enumerate table
    # id,type,access,dependent_ids,deleted
    # product.decendents set of eager Predicate
  end
end
