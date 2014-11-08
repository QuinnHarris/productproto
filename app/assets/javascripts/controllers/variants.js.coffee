Ink.VariantGroupsController = Ember.Controller.extend
  needs: 'variantGroup'
  properties: [9]
  variantGroups: Ember.computed 'properties', ->
    product_data.variantGroups(@get('properties'), 'sizes')

  quantity: Ember.computed 'controller.variantGroup.@each.quantity', ->
    10
    #controller.variantGroup.get('@each').reduce ((sum, v) -> sum + parseInt(v.get('quantity'))), 0

  margin: Ember.computed 'unit_price', 'unit_cost', (key, value) ->
    10.0


Ink.VariantGroupController = Ember.ArrayController.extend
  itemController: 'variant'

  quantity: Ember.computed '@each.quantity', ->
    @_subControllers.reduce ((sum, v) -> sum + parseInt(v.get('quantity'))), 0

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
      ((unit_price - @get('unit_cost')) * 100.0 / unit_price).toFixed(1)

Ink.VariantController = Ember.ObjectController.extend
  quantity: 0
