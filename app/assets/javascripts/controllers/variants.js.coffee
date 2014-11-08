Ink.VariantGroupsController = Ember.Controller.extend
  properties: [9]
  variantGroups: Ember.computed 'properties', ->
    for list in product_data.variantGroups(@get('properties'), 'sizes')
      { variants: list }

Ink.VariantGroupController = Ember.ObjectController.extend
  needs: 'variantGroups'
  itemController: 'variant'

  quantity: Ember.computed 'variants.@each.quantity', ->
    10 #@get('variants').reduce ((sum, v) -> sum + v.get('quantity')), 0


  properties: Ember.computed 'controllers.variantGroups.properties', ->
    @get('controllers.variantGroups.properties').concat([@get('variants')[0].id])

  basis: Ember.computed 'properties', ->
    product_data.getCostPrice(@get('properties'))

  unit_price: Ember.computed 'quantity', 'basis', ->
    product_data.getPrice(@get('basis').prices, 100)


  total_price: Ember.computed 'quantity', 'unit_price', ->
    @get('quantity') * @get('unit_price')

  unit_cost: Ember.computed 'quantity', 'basis', ->
    product_data.getPrice(@get('basis').costs, 100)

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
      ((unit_price - @get('unit_cost')) * 100.0 / unit_price).toFixed(1)

Ink.VariantController = Ember.ObjectController.extend
  needs: 'variantGroup'
  quantity: 0
