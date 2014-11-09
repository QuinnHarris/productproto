Ink.VariantGroupsController = Ember.ArrayController.extend
  itemController: 'variantGroup'
  properties: [9]
  # Use arrangedContent to allow actual content to depend on properties
  # Regular model is not used
  arrangedContent: Ember.computed 'properties', ->
    [[ { id: 1, name: '?' } ]].concat product_data.variantGroups(@get('properties'), 'sizes')

  quantity: Ember.computed '@each.quantity', ->
    @get('@each.quantity').reduce ((a, b) -> a + b), 0

  total_price: Ember.computed '@each.total_price', ->
    @get('@each.total_price').reduce ((a, b) -> a + b), 0

  total_cost: Ember.computed '@each.total_cost', ->
    @get('@each.total_cost').reduce ((a, b) -> a + b), 0

  profit: Ember.computed '@each.profit', ->
    @get('@each.profit').reduce ((a, b) -> a + b), 0

  margin: Ember.computed 'total_price', 'total_cost', (key, value) ->
    unit_price = @get('total_price')
    return '' unless unit_price
    ((unit_price - @get('total_cost')) * 100.0 / unit_price).toFixed(1)


Ink.VariantGroupController = Ember.ArrayController.extend
  itemController: 'variant'

  # why doesn't @first work in the template?
  firstRow: Ember.computed ->
    @get('parentController')._subControllers[0] == this

  quantity: Ember.computed '@each.quantity', ->
    @get('@each.quantity').reduce ((sum, v) -> sum + parseInt(v)), 0

  parentQuantity: Ember.computed.alias('parentController.quantity')

  properties: Ember.computed 'parentController.properties', ->
    @get('parentController.properties').concat([@model[0].id])

  basis: Ember.computed 'properties', ->
    product_data.getCostPrice(@get('properties'))

  unit_price: Ember.computed 'parentQuantity', 'basis', ->
    product_data.getPrice(@get('basis').prices, @get('parentQuantity'))


  total_price: Ember.computed 'quantity', 'unit_price', ->
    @get('quantity') * @get('unit_price')

  unit_cost: Ember.computed 'parentQuantity', 'basis', ->
    product_data.getPrice(@get('basis').costs, @get('parentQuantity'))

  total_cost: Ember.computed 'quantity', 'unit_cost', ->
    @get('quantity') * @get('unit_cost')

  profit: Ember.computed 'quantity', 'unit_price', 'unit_cost', (key, value) ->
    if value
      @set('unit_price',
           @get('unit_cost') + parseFloat(value) / @get('quantity') )
    else
      @get('quantity') * (@get('unit_price') - @get('unit_cost'))

  margin: Ember.computed 'unit_price', 'unit_cost', (key, value) ->
    if value
      @set('unit_price',
           (@get('unit_cost') / (1-parseFloat(value)/100.0)).toFixed(3) )
    else
      unit_price = @get('unit_price')
      return '' unless unit_price
      ((unit_price - @get('unit_cost')) * 100.0 / unit_price).toFixed(1)

Ink.VariantController = Ember.ObjectController.extend
  quantity: 0
