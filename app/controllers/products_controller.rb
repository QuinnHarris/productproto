class ProductsController < ApplicationController
  def index
    prop_id = 0
    @sizes = %w(S M L XL 2XL 3XL 4XL 5XL).map { |n| { id: prop_id += 1, name: n }}
    @colors = %w(Ash Black Cardinal\ Red Carolina\ Blue Charcoal Dark\ Chocolate Dark\ Heather Forest\ Green Indigo\ Blue Light\ Blue Maroon Natural Navy Orange Prairie\ Dust Purple Red Royal Sand Sport\ Grey White)
    colors_clearance = %w(Yellow\ Haze Kiwi Prairie\ Dust)
    @colors += colors_clearance
    @colors = @colors.map { |c| { id: prop_id += 1, name: c } }
    @light_colors = %w(Ash Carolina\ Blue Light\ Blue Light\ Pink Natural Orange Safety\ Green Safety\ Orange Sport\ Grey White Prairie\ Dust Yellow\ Haze Sand)
    # basis, fixed, unit, per decoration
    @costs = [
        # All
        { predicate: [[1,2,3,4]], priority: 0, basis: 1, breaks: [[1, 7.5], [12, 6.32], [72, 5.47]] },
        { predicate: [5], priority: 0, basis: 1, breaks: [[1, 9.73], [12, 8.21], [72, 7.1]] },   # 2XL
        { predicate: [6], priority: 0, basis: 1, breaks: [[1, 10.24], [12, 8.57], [72, 7.37]] }, # 3XL
        { predicate: [7], priority: 0, basis: 1, breaks: [[1, 10.44], [12, 8.7], [72, 7.47]] },  # 4XL
        { predicate: [8], priority: 0, basis: 1, breaks: [[1, 10.83], [12, 8.98], [72, 7.67]] }, # 5XL

        # Ash, Sport Grey
        { predicate: [[9,28],[1,2,3,4]], priority: 1, basis: 1, breaks: [[1, 7.1], [12, 5.98], [72, 5.17]] },
        { predicate: [[9,28],5], priority: 1, basis: 1, breaks: [[1, 9.13], [12, 7.69], [72, 6.65]] },   # 2XL
        { predicate: [[9,28],6], priority: 1, basis: 1, breaks: [[1, 9.63], [12, 8.04], [72, 6.91]] }, # 3XL
        { predicate: [[9,28],7], priority: 1, basis: 1, breaks: [[1, 9.80], [12, 8.16], [72, 7.00]] },  # 4XL
        { predicate: [[9,28],8], priority: 1, basis: 1, breaks: [[1, 10.10], [12, 8.42], [72, 7.19]] }, # 5XL

        # Closout: Kiwi,
        { predicate: [[30,31,32]], priority: 1, breaks: [[1, 1.64]] },

        { predicate: [30,6], discontinued: true },
    ]

    meta = %w(Color\ Match).map { |n| { id: prop_id += 1, name: n } }
    locations = %w(Front Back).map { |n| { id: prop_id += 1, name: n } }
    techniques = %w(Screen\ Print Photo\ Print).map { |n| { id: prop_id += 1, name: n } }
    decorations = locations.map { |loc| techniques.map { |tech| { id: prop_id += 1, location: loc[:id], technique: tech[:id] } } }.flatten

    @prices = [
        { priority: 10, op: :mult, breaks: [{marginal: 1.3}] },
        { predicate: techniques[0][:id], priority: 20, op: :add, basis: 2, breaks: [[10, 50.0]] },
        { predicate: techniques[0][:id], priority: 20, op: :add, basis: 3, breaks: [[10, 0.50]] },
        { predicate: techniques[1][:id], priority: 20, op: :add, basis: 3, breaks: [[1, 1.50]] },

        { predicate: meta[0][:id], priority: 20, op: :add, breaks: [{ fixed: 20.0 }] }
    ]

    @data = {
        properties: {
            colors: @colors,
            sizes: @sizes,
        },
        locations: locations,
        techniques: techniques,
        decorations: decorations,

        costs: @costs,
        prices: @prices
    }
  end
end
