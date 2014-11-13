Ink.VariantsController = Ember.ArrayController.extend
  itemController: 'variantGroups'

  currentIndex: 0

  # Why doesn't sum or even @get .. @each work ?
  quantity: Ember.computed '@each.quantity', ->
    @_subControllers.reduce ((sum, v) -> sum + v.get('quantity')), 0
  total_price: Ember.computed '@each.total_price', ->
    @_subControllers.reduce ((sum, v) -> sum + v.get('total_price')), 0
  total_cost: Ember.computed '@each.total_price', ->
    @_subControllers.reduce ((sum, v) -> sum + v.get('total_cost')), 0
  profit: Ember.computed '@each.profit', ->
    @_subControllers.reduce ((sum, v) -> sum + v.get('profit')), 0

  margin: Ember.computed 'total_price', 'total_cost', (key, value) ->
    unit_price = @get('total_price')
    return '' unless unit_price
    ((unit_price - @get('total_cost')) * 100.0 / unit_price).toFixed(1)

  propertiesValue: Ember.computed.alias('propertiesController.value')

  propertiesValueChanged: Ember.observer 'propertiesController.value', ->
    return unless @get('model.length') > 0
    value = @get('propertiesController.value')
    if c = @_subControllers.find((c) -> Ember.compare(c.get('properties'), value) == 0)
      @set('currentIndex', @_subControllers.indexOf(c))
    @model[@get('currentIndex')].set('properties', value)

  currentIndexChanged: Ember.observer 'currentIndex', ->
    @set('propertiesController.value', @model[@get('currentIndex')].get('properties'))

  optionTypes: Ember.computed ->
    p.name for p in product_data.data.properties

  actions:
    addGroup: ->
      @model.unshiftObject(Ember.Object.create(properties: [null]))

# Can't use ArrayController because contents depends on properties input
Ink.VariantGroupsController = Ember.ObjectController.extend
  #properties: [null]
  groups: Ember.computed 'properties', ->
    for m in [[ { id: 1, name: '?' } ]].concat product_data.variantGroups(@get('properties'))
      Ink.VariantGroupController.create
        target: @,
        parentController: @,
        container: @get('container'),
        model: m

  selected: Ember.computed 'parentController.currentIndex', 'parentController.@each', ->
    @get('parentController.model').indexOf(@get('model')) == @get('parentController.currentIndex')

  actions:
    select: ->
      @set('parentController.currentIndex', @get('parentController.model').indexOf(@get('model')))

  onlyOne: Ember.computed 'parentController.@each', ->
    @get('parentController.length') == 1

  options: Ember.computed 'properties', ->
    properties = @get('properties')
    for prop, i in product_data.data.properties
      id = properties[i]
      prop.list.findBy('id', id)

  # Why doesn't Ember.computer.sum work?
  quantity: Ember.computed 'groups.@each.quantity', ->
    @get('groups.@each.quantity').reduce ((sum, v) -> sum + v), 0
  total_price: Ember.computed 'groups.@each.total_price', ->
    @get('groups.@each.total_price').reduce ((sum, v) -> sum + v), 0
  total_cost: Ember.computed 'groups.@each.total_cost', ->
    @get('groups.@each.total_cost').reduce ((sum, v) -> sum + v), 0
  profit: Ember.computed 'groups.@each.profit', ->
    @get('groups.@each.profit').reduce ((sum, v) -> sum + v), 0

  margin: Ember.computed 'total_price', 'total_cost', (key, value) ->
    unit_price = @get('total_price')
    return '' unless unit_price
    ((unit_price - @get('total_cost')) * 100.0 / unit_price).toFixed(1)


Ink.VariantGroupController = Ember.ArrayController.extend
  itemController: 'variant'
  needs: ['variantGroup']

  parentProperties: Ember.computed.alias('parentController.properties')

  # why doesn't @first work in the template?
  firstRow: Ember.computed ->
    @model[0].name == '?'

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
