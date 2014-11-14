class ProductsController < ApplicationController
  def index
    prop_id = 0
    @sizes = %w(S M L XL 2XL 3XL 4XL 5XL).map { |n| { id: prop_id += 1, name: n }}
    @colors = %w(Ash Black Cardinal\ Red Carolina\ Blue Charcoal Dark\ Chocolate Dark\ Heather Forest\ Green Indigo\ Blue Light\ Blue Maroon Natural Navy Orange Prairie\ Dust Purple Red Royal Sand Sport\ Grey White)
    colors_clearance = %w(Yellow\ Haze Kiwi Prairie\ Dust)
    @colors += colors_clearance
    @light_colors = %w(Ash Carolina\ Blue Light\ Blue Light\ Pink Natural Orange Safety\ Green Safety\ Orange Sport\ Grey White Prairie\ Dust Yellow\ Haze Sand)
    @colors = @colors.map { |c| { id: prop_id += 1, name: c, image: "/gildan/Gildan_#{c.gsub(' ','')}.gif", image_tint: @light_colors.include?(c) ? 'light' : 'dark' } }

    # basis, fixed, unit, per decoration
    @costs = [
        # All
        { predicate: [[1,2,3,4]], priority: 0, basis: 1, breaks: [{ n: 1, v: 7.5 }, { n: 12, v: 6.32 }, { n: 72, v: 5.47 }] },
        { predicate: [5], priority: 0, basis: 1, breaks: [{ n: 1, v: 9.73 }, { n: 12, v: 8.21 }, { n: 72, v: 7.1 }] },   # 2XL
        { predicate: [6], priority: 0, basis: 1, breaks: [{ n: 1, v: 10.24 }, { n: 12, v: 8.57 }, { n: 72, v: 7.37 }] }, # 3XL
        { predicate: [7], priority: 0, basis: 1, breaks: [{ n: 1, v: 10.44 }, { n: 12, v: 8.7 }, { n: 72, v: 7.47 }] },  # 4XL
        { predicate: [8], priority: 0, basis: 1, breaks: [{ n: 1, v: 10.83 }, { n: 12, v: 8.98 }, { n: 72, v: 7.67 }] }, # 5XL

        # Ash, Sport Grey
        { predicate: [[9,28],[1,2,3,4]], priority: 1, basis: 1, breaks: [{ n: 1, v: 7.1 }, { n: 12, v: 5.98 }, { n: 72, v: 5.17 }] },
        { predicate: [[9,28],5], priority: 1, basis: 1, breaks: [{ n: 1, v: 9.13 }, { n: 12, v: 7.69 }, { n: 72, v: 6.65 }] },   # 2XL
        { predicate: [[9,28],6], priority: 1, basis: 1, breaks: [{ n: 1, v: 9.63 }, { n: 12, v: 8.04 }, { n: 72, v: 6.91 }] }, # 3XL
        { predicate: [[9,28],7], priority: 1, basis: 1, breaks: [{ n: 1, v: 9.80 }, { n: 12, v: 8.16 }, { n: 72, v: 7.00 }] },  # 4XL
        { predicate: [[9,28],8], priority: 1, basis: 1, breaks: [{ n: 1, v: 10.10 }, { n: 12, v: 8.42 }, { n: 72, v: 7.19 }] }, # 5XL

        # Closout: Kiwi,
        { predicate: [[30,31,32]], priority: 1, breaks: [{ n: 1, v: 1.64 }] },
    ]

    @inventory = [
        { predicate: [30,6], quantity: 0 },
    ]

    meta = %w(Color\ Match).map { |n| { id: prop_id += 1, name: n } }
    locations = %w(Front Back).map { |n| { id: prop_id += 1, name: n } }
    techniques = %w(Screen\ Print Photo\ Print).map { |n| { id: prop_id += 1, name: n } }
    decorations = locations.map { |loc| techniques.map { |tech| { id: prop_id += 1, location: loc[:id], technique: tech[:id] } } }.flatten

    @prices = [
        { priority: 10, op: :mult, breaks: [{ n: 1, v: 1.3 }] },
        { predicate: [techniques[0][:id]], priority: 20, op: :add, basis: 2, breaks: [{ n: 10, v: 50.0 }] },
        { predicate: [techniques[0][:id]], priority: 20, op: :add, basis: 3, breaks: [{ n: 10, v: 0.50 }] },
        { predicate: [techniques[1][:id]], priority: 20, op: :add, basis: 3, breaks: [{ n: 1, v: 1.50 }] },

        { predicate: [meta[0][:id]], priority: 20, op: :add, breaks: [{ fixed: 20.0 }] }
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
