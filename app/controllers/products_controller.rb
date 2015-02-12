class ProductsController < ApplicationController
  def index
    prop_id = 0
    @sizes = %w(S M L XL 2XL 3XL 4XL 5XL).map { |n| { id: prop_id += 1, name: n }}
    @colors = %w(Ash Black Cardinal\ Red Carolina\ Blue Charcoal Dark\ Chocolate Dark\ Heather Forest\ Green Indigo\ Blue Light\ Blue Maroon Natural Navy Orange Prairie\ Dust Purple Red Royal Sand Sport\ Grey White)
    colors_clearance = %w(Yellow\ Haze Kiwi Prairie\ Dust)
    @colors += colors_clearance
    @light_colors = %w(Ash Carolina\ Blue Light\ Blue Light\ Pink Natural Orange Safety\ Green Safety\ Orange Sport\ Grey White Prairie\ Dust Yellow\ Haze Sand)
    @colors = @colors.map { |c| { id: prop_id += 1, name: c, image: "/gildan/Gildan_#{c.gsub(' ','')}.gif", image_tint: @light_colors.include?(c) ? 'light' : 'dark' } }

    @inventory = [
        { predicate: [30,6], quantity: 0 },
    ]

    meta = %w(Color\ Match).map { |n| { id: prop_id += 1, name: n } }
    locations = %w(Front Back).map { |n| { id: prop_id += 1, name: n } }
    techniques = %w(Screen\ Print Photo\ Print Embroidery).map { |n| { id: prop_id += 1, name: n } }
    screen_standard_colors = [
      { name: 'White', color: 'FFFFFF'},
      { name: 'Black', color: '000000'},
      { name: 'Red', color: 'FF0000' },
      { name: 'Green', color: '00FF00' },
      { name: 'Blue', color: '0000FF' },
      { name: 'Yellow', color: 'FFFF00' },
      { name: 'Cyan', color: '00FFFF' },
      { name: 'Magenta', color: 'FF00FF' },
    ]
    screen_standard_colors = screen_standard_colors.map { |n| n.merge(id: prop_id += 1) }
    techniques[0].merge!(class: 'color', standard_colors: screen_standard_colors )
    techniques[2].merge!( class: 'number', desc: 'stiches' )
    decorations = locations.map { |loc| techniques.map { |tech| { id: prop_id += 1, location: loc[:id], technique: tech[:id] } } }.flatten
    locations << { id: prop_id += 1, name: 'Front Pocket' }
    decorations << { id: prop_id += 1, location: locations.last[:id], technique: techniques.last[:id] }
    techniques += %w(None).map { |n| { id: prop_id += 1, name: n } }

    # Hardcoded predicates
    # -1 Product Variant
    # -2 Decoration

    @costs = [
        # All
        { predicate: [[1,2,3,4]], priority: 0, input: 1, breaks: [{ n: 1, v: 7.5 }, { n: 12, v: 6.32 }, { n: 72, v: 5.47 }] },
        { predicate: [5], priority: 0, input: 1, breaks: [{ n: 1, v: 9.73 }, { n: 12, v: 8.21 }, { n: 72, v: 7.1 }] },   # 2XL
        { predicate: [6], priority: 0, input: 1, breaks: [{ n: 1, v: 10.24 }, { n: 12, v: 8.57 }, { n: 72, v: 7.37 }] }, # 3XL
        { predicate: [7], priority: 0, input: 1, breaks: [{ n: 1, v: 10.44 }, { n: 12, v: 8.7 }, { n: 72, v: 7.47 }] },  # 4XL
        { predicate: [8], priority: 0, input: 1, breaks: [{ n: 1, v: 10.83 }, { n: 12, v: 8.98 }, { n: 72, v: 7.67 }] }, # 5XL

        # Ash, Sport Grey
        { predicate: [[9,28],[1,2,3,4]], priority: 1, input: 1, breaks: [{ n: 1, v: 7.1 }, { n: 12, v: 5.98 }, { n: 72, v: 5.17 }] },
        { predicate: [[9,28],5], priority: 1, input: 1, breaks: [{ n: 1, v: 9.13 }, { n: 12, v: 7.69 }, { n: 72, v: 6.65 }] },   # 2XL
        { predicate: [[9,28],6], priority: 1, input: 1, breaks: [{ n: 1, v: 9.63 }, { n: 12, v: 8.04 }, { n: 72, v: 6.91 }] }, # 3XL
        { predicate: [[9,28],7], priority: 1, input: 1, breaks: [{ n: 1, v: 9.80 }, { n: 12, v: 8.16 }, { n: 72, v: 7.00 }] },  # 4XL
        { predicate: [[9,28],8], priority: 1, input: 1, breaks: [{ n: 1, v: 10.10 }, { n: 12, v: 8.42 }, { n: 72, v: 7.19 }] }, # 5XL

        # Closout: Kiwi,
        { predicate: [[30,31,32]], priority: 2, input: 1, breaks: [{ n: 1, v: 1.64 }] },

        { predicate: [techniques[0][:id]], priority: 1, input: 1, breaks: [{ n: 1, v: 40.0 }] },
        { predicate: [techniques[0][:id]], priority: 1, input: 1, mult: [0,1], breaks: [{ n: 1, v: 0.40 }] },
        { predicate: [techniques[1][:id]], priority: 1, input: 1, breaks: [{ n: 1, v: 1.20 }] },

        #{ predicate: [techniques[0][:id], screen_standard_colors[0][:id]],
        #  priority: 1, input: 1, mult: 1, breaks: [{ n: 1, v: 0.40 }] },

        { predicate: [meta[0][:id]], priority: 1, breaks: [{ fixed: 16.0 }] }
    ]

    @prices = [
        { predicate: [-1], priority: 10, op: :mult, input: 1, breaks: [{ n: 1, v: 1.4285714285714286 }] },

        { predicate: [-2], priority: 10, op: :mult, input: 1, breaks: [{ n: 1, v: 1.25 }] },
        { predicate: [-2], priority: 10, op: :mult, input: 1, mult: [0,1], breaks: [{ n: 1, v: 1.25 }] },

    ]

    @images = @colors.map do |c|
      %w(Flat Model).map do |name|
        { predicate: [c[:id]],
          src: "/gildan/G2400_#{c[:name].gsub(' ', '').capitalize}_#{name}_Front.jpg"
        }
      end
    end.flatten

    @data = {
        properties: [
            { name: 'colors', list: @colors }
        ],
        variant_group: { name: 'sizes', list: @sizes },
        locations: locations,
        techniques: techniques,
        decorations: decorations,

        costs: @costs,
        prices: @prices,
        inventory: @inventory,

        images: @images
    }
  end
end
