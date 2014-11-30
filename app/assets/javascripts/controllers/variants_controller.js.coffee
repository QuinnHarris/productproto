Ink.VariantsController = Ember.ArrayController.extend
  itemController: 'variantGroups'

  #content: Em.ArrayProxy.create(content: []),

  # Can this be initiated before any other computed properties?
  # Init runs before any properties are set
  setBlocks: (->
    pd = @get('product_data')
    pi = @get('product_instance')

    added = []
    pi.get('variants').forEach (v) =>
      pred = v.get('property_ids')
      prop = pd.propertyFromPredicate pred
      unless added.find((p) -> Em.isEqual(p, prop))
        added.push prop
        @addObject prop

    if added.length == 0
      @addObject [null]

    @set 'current', @get('firstObject')
  ).observes('product_instance')

  variants: Ember.computed.alias('product_instance.variants')

  # Why doesn't sum or even @get .. @each work ?
  quantity: Ember.computed '@each.quantity', ->
    @reduce ((sum, v) -> sum + v.get('quantity')), 0
  total_price: Ember.computed '@each.total_price', ->
    @reduce ((sum, v) -> sum + v.get('total_price')), 0
  total_cost: Ember.computed '@each.total_cost', ->
    @reduce ((sum, v) -> sum + v.get('total_cost')), 0
  profit: Ember.computed '@each.profit', ->
    @reduce ((sum, v) -> sum + v.get('profit')), 0

  margin: Ember.computed 'total_price', 'total_cost', (key, value) ->
    unit_price = @get('total_price')
    return '' unless unit_price
    ((unit_price - @get('total_cost')) * 100.0 / unit_price).toFixed(1)

  propertiesValue: Ember.computed.alias('propertiesController.value')

  propertiesValueChanged: Ember.observer 'propertiesController.value', ->
    return unless @get('current')
    value = @get('propertiesController.value')
    if c = @.find((c) -> Ember.compare(c.get('properties'), value) == 0)
      @set('current', c)
    else
      prev = @get('current.properties')

      @get('variants').forEach (v) ->
        ids = v.get('property_ids')
        ids.push(null) until ids.length >= prev.length + 1
        if prev.every((id) -> ids.contains(id))
          ids = ids.map (id) ->
            i = prev.indexOf(id)
            if i == -1
              id
            else
              value[i]
          v.set('property_ids', ids.compact())
          v.save()

      @get('current').set('properties', value)

  currentChanged: Ember.observer 'current', ->
    return unless @get('propertiesController.value')
    @set 'propertiesController.value', @get('current.properties')

  currentChange: (->
    current = @get('current')
    if current && current.get('quantity') == 0
      @removeObject current
  ).observesBefore('current')

  optionTypes: Ember.computed ->
    p.name for p in product_data.data.properties

  actions:
    addGroup: ->
      next_prop = for list, i in @get('propertiesController.availableIds')
        list.find (id) ->
          !@find (c) -> c.get('properties')[i] == id

      @addObject next_prop
      @set('current', @get('lastObject'))

# Can't use ArrayController because contents depends on properties input
Ink.VariantGroupsController = Ember.ArrayController.extend
  itemController: 'variantGroup'

  # Content is normally alias of model on ArrayController.
  # But this computes the content from the model (data for controller)
  # So the alias is broken here
  content: null,

  properties: Em.computed.alias('model')

  # Content usually doesn't change when parent properties change
  # So don't change content if not necissary for a noticable performace improvement
  nullGroup: [{ id: 1, name: '?' }]
  setGroups: (->
    current = @get('content')
    expected = [@get('nullGroup')].concat product_data.variantGroups(@get('properties'))
    unless Em.isEqual(current, expected)
      @set 'content', expected
  ).observes('properties').on('init')

  selected: Ember.computed 'parentController.current', ->
    @get('parentController.current') == @

  actions:
    select: ->
      @set('parentController.current', @)

  rowSpan: Ember.computed 'this.[]', ->
    @get('length') + 2

  showFooter: Ember.computed '@each.quantity', ->
    @get('@each.quantity').filter((v) -> v > 0).length > 1

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

  quantity: Ember.computed.sum '@each.quantity'
  total_price: Ember.computed.sum '@each.total_price'
  total_cost: Ember.computed.sum '@each.total_cost'
  profit: Ember.computed.sum '@each.profit'

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

  quantity: Ember.computed.sum '@each.quantity'

  quantityBasis: Ember.computed 'quantity',
    'parentController.quantity',
    'parentController.parentController.quantity', ->
      [@get('quantity'),
       @get('parentController.quantity'),
       @get('parentController.parentController.quantity')]

  show: Ember.computed 'quantity', ->
    @get('quantity') != 0

  properties: Ember.computed 'parentController.properties', ->
    @get('parentController.properties').concat([@model[0].id])

  basis: Ember.computed 'properties', ->
    product_data.getCostPrice([-1].concat(@get('properties')))

  unit_price_default: Ember.computed 'quantityBasis', 'basis', ->
    product_data.getPrice(@get('basis').prices, @get('quantityBasis'))

  unit_price: Ember.computed 'unit_price_value', 'unit_price_default', ->
    @get('unit_price_value') ? @get('unit_price_default')

  total_price: Ember.computed 'quantity', 'unit_price', ->
    @get('quantity') * @get('unit_price')

  unit_cost_default: Ember.computed 'quantityBasis', 'basis', ->
    product_data.getPrice(@get('basis').costs, @get('quantityBasis'))

  unit_cost: Ember.computed 'unit_cost_value', 'unit_cost_default', ->
    @get('unit_cost_value') ? @get('unit_cost_default')

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
  #quantity: 0

  properties: Ember.computed 'parentController.parentProperties', ->
    @get('parentController.parentProperties').concat([@get('id')])

  variants: Ember.computed.alias('parentController.parentController.parentController.variants')

  variant: Ember.computed 'variants', 'properties', ->
    properties = @get('properties').compact()
    variants = @get('variants')
    variant = variants.find (v) ->
      ids = v.get('property_ids')
      return false unless ids.length == properties.length
      ids.every (id) -> properties.contains(id)
    return variant if variant
    @store.createRecord('variant',
      instance: variants.toArray()[0].get('instance'),
      quantity: 0,
      property_ids: properties
    )

  quantity: Ember.computed 'variant', (key, value) ->
    variant = @get('variant')
    if value
      value = parseInt(value)
      variant.set('quantity', value)
      value
    else
      variant.get('quantity')