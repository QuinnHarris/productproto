require_relative 'import'

class SampleValueAdder < GenericImport
  def define_schema
    d.apply_property('locations', :natural_single)
    d.apply_property('decoration', :natural_single)
    d.apply_property('imprint color', :natural_single)
    d.apply_property('count', :natural_single)
  end

  def define_data
    price_property = d.find_property('price', :function_discrete)
    imprint_color = d.find_property('imprint color')

    location = d.find_property('locations')
    locations = location.get_values('locations', %w(Front Back))


    single_instance_predicate = d.find_property('item_code')

    # Create instance dependent on imprint color and location.
    sp = d.set_value('decoration', 'Screen Print')
    sp_price = price_property.get_value(input: { 0 => [single_instance_predicate] },
      breaks: { [12] => 1000, [72] => 800, [144] => 700 }
    )
    sp_price.set_predicate([sp])

    # Setup
    price_property.get_value(scopes: [location, imprint_color], breaks: { [] => 50000 })



    stiches = d.set_value('count', 'stitches')
    em = d.set_value('decoration', 'Embroidery')
    stiches.implies em
    em_price = price_property.get_value(inputs: { 1 => single_instance_predicate },
                                        breaks: { } # 0 is stitches, 1 is quantity
    )
    stiches.implies em_price

  end
end

