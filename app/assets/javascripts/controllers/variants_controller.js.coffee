Ink.VariantsController = Ember.Controller.extend
  #itemController: 'variantGroups'

  createBlock: (properties) ->
    Ink.VariantGroupsController.create(
      target: @,
      parentController: @,
      container: @get('container'),
      properties: properties )

  initGroups: (->
    current = @createBlock([null])

    @set 'blocks', Ember.ArrayProxy.create(content: [current] )
    @set 'current', current
  ).on('init')

  # Why doesn't sum or even @get .. @each work ?
  quantity: Ember.computed 'blocks.@each.quantity', ->
    @get('blocks').reduce ((sum, v) -> sum + v.get('quantity')), 0
  total_price: Ember.computed 'blocks.@each.total_price', ->
    @get('blocks').reduce ((sum, v) -> sum + v.get('total_price')), 0
  total_cost: Ember.computed 'blocks.@each.total_cost', ->
    @get('blocks').reduce ((sum, v) -> sum + v.get('total_cost')), 0
  profit: Ember.computed 'blocks.@each.profit', ->
    @get('blocks').reduce ((sum, v) -> sum + v), 0

  margin: Ember.computed 'total_price', 'total_cost', (key, value) ->
    unit_price = @get('total_price')
    return '' unless unit_price
    ((unit_price - @get('total_cost')) * 100.0 / unit_price).toFixed(1)

  propertiesValue: Ember.computed.alias('propertiesController.value')

  propertiesValueChanged: Ember.observer 'propertiesController.value', ->
    value = @get('propertiesController.value')
    if c = @get('blocks').find((c) -> Ember.compare(c.get('properties'), value) == 0)
      @set('current', c)
    else
      @get('current').set('properties', value)

  currentChanged: Ember.observer 'current', ->
    return unless @get('propertiesController.value')
    @set 'propertiesController.value', @get('current.properties')

  optionTypes: Ember.computed ->
    p.name for p in product_data.data.properties

  actions:
    addGroup: ->
      blocks = @get('blocks')
      next_prop = for list, i in @get('propertiesController.availableIds')
        list.find (id) ->
          !blocks.find (c) -> c.get('properties')[i] == id

      current = @createBlock(next_prop)
      blocks.addObject current
      @set('current', current)

# Can't use ArrayController because contents depends on properties input
Ink.VariantGroupsController = Ember.Controller.extend
  groups: Ember.computed 'properties', ->
    Ember.ArrayProxy.create(content:
      (for m in [[ { id: 1, name: '?' } ]].concat product_data.variantGroups(@get('properties'))
        Ink.VariantGroupController.create
          target: @,
          parentController: @,
          container: @get('container'),
          model: m
      ) )

  selected: Ember.computed 'parentController.current', ->
    @get('parentController.current') == @

  actions:
    select: ->
      @set('parentController.current', @)

  rowSpan: Ember.computed 'groups.@each', ->
    @get('groups.length') + 2

  showFooter: Ember.computed 'groups.@each.quantity', ->
    @get('groups.@each.quantity').filter((v) -> v > 0).length > 1

  options: Ember.computed 'properties', ->
    properties = @get('properties')
    for prop, i in product_data.data.properties
      id = properties[i]
      prop.list.findBy('id', id)

  imageSrc: Ember.computed 'options', ->
    options = @get('options')
    return null unless options and options[0]
    ids = options.mapBy('id')
    img = product_data.data.images.find (img) ->
      img.predicate.every (i) -> ids.contains(i)
    img && img.src

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
  # Not used now with dummy first row
  firstRow: Ember.computed ->
    @model[0].name == '?'

  quantity: Ember.computed '@each.quantity', ->
    @get('@each.quantity').reduce ((sum, v) -> sum + parseInt(v)), 0

  parentQuantity: Ember.computed.alias('parentController.quantity')

  show: Ember.computed 'quantity', ->
    @get('quantity') != 0

  properties: Ember.computed 'parentController.properties', ->
    @get('parentController.properties').concat([@model[0].id])

  basis: Ember.computed 'properties', ->
    product_data.getCostPrice(@get('properties'))

  unit_price_default: Ember.computed 'parentQuantity', 'basis', ->
    product_data.getPrice(@get('basis').prices, @get('parentQuantity'))

  unit_price: Ember.computed 'unit_price_value', 'unit_price_default', ->
    value = @get('unit_price_value')
    value = @get('unit_price_default') unless value?
    value

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
