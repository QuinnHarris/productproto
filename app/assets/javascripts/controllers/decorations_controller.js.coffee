Ink.DecorationsController = Ember.ObjectController.extend
  quantity: Ember.computed.alias 'variantsController.quantity'

  currentLocations: Ember.computed 'techniqueId', ->
    techniqueId = @get('techniqueId')
    model = @get('model')
    model.decorations.filter((d) ->
      d.technique == techniqueId
    ).map (d) ->
      model.locations.find (l) -> l.id == d.location

  useColors: Ember.computed 'technique', ->
    return unless technique = @get('technique')
    technique.class == 'color'

  useNumber: Ember.computed 'technique', ->
    return unless technique = @get('technique')
    technique.class == 'number'


Ink.DecorationController = Ember.ObjectController.extend
  properties: Ember.computed 'parentController.techniqueId', ->
    [@get('parentController.techniqueId')]

  basis: Ember.computed 'properties', ->
    props = [-2].concat(@get('properties'))
    product_data.getCostPrice(props)

  quantityBasis: Ember.computed 'count', 'parentController.quantity', ->
    [@get('count'), @get('parentController.quantity')]

  entryList: Ember.computed 'basis', ->
    @get('basis').axis

  #total_price: Ember.computed 'entryList', ->
  #  @get('entryList').reduce ((sum, v) -> sum + v.get('total_price')), 0
  #total_cost: Ember.computed.sum 'entryList.@each.total_cost'
  #profit: Ember.computed.sum 'entryList.@each.profit'


Ink.DecorationEntryController = Ember.ObjectController.extend
  quantityBasis: Ember.computed.alias('parentController.quantityBasis')

  description: Ember.computed 'mult', ->
    mult = @get('mult')
    if mult.length == 1 and mult[0] == 0
      'Setup'
    else
      'Unit'

  quantity: Ember.computed 'mult', 'quantityBasis', ->
    qtyBasis = @get('quantityBasis')
    mult = @get('mult')
    mult.reduce(( (a, i) -> a * (qtyBasis[i] ? 1) ), 1)

  quantityShow: Ember.computed 'mult', 'quantityBasis', ->
    qtyBasis = @get('quantityBasis')
    mult = @get('mult')
    qty = mult.map((i) -> qtyBasis[i] ? 1)
    return qty[0] if qty.length == 1
    qty = qty.filter((e) -> e != 1)
    return qty[0] if qty.length == 1
    qty.join(' x ') + ' = ' + @get('quantity')

  unit_price_default: Ember.computed 'quantity', ->
    basis = @get('parentController.basis').prices
    input = @get('input')
    mult = @get('mult')
    basis = basis.filter((b) -> b.input == input && b.mult == mult)
    qtyBasis = @get('quantityBasis')
    product_data.getPrice(basis, qtyBasis)

  unit_price: Ember.computed 'unit_price_value', 'unit_price_default', ->
    @get('unit_price_value') ? @get('unit_price_default')

  total_price: Ember.computed 'quantity', 'unit_price', ->
    @get('quantity') * @get('unit_price')

  unit_cost_default: Ember.computed 'quantity', ->
    basis = @get('parentController.basis').costs
    input = @get('input')
    mult = @get('mult')
    basis = basis.filter((b) -> b.input == input && b.mult == mult)
    qtyBasis = @get('quantityBasis')
    product_data.getPrice(basis, qtyBasis)

  unit_cost: Ember.computed 'unit_cost_value', 'unit_cost_default', ->
    @get('unit_cost_value') ? @get('unit_cost_default')

  total_cost: Ember.computed 'quantity', 'unit_price', ->
    @get('quantity') * @get('unit_cost')

  profit_default: Ember.computed 'quantity', 'unit_price_default', 'unit_cost_default', ->
    @get('quantity') * (@get('unit_price_default') - @get('unit_cost_default'))

  profit: Ember.computed 'quantity', 'unit_price', 'unit_cost', (key, value) ->
    if arguments.length == 1
      @get('quantity') * (@get('unit_price') - @get('unit_cost'))
    else
      ret = @get('unit_cost') + parseFloat(value) / @get('quantity')
      ret -= (ret % 0.01)
      @set('unit_price_value', ret)
      value

  margin_default: Ember.computed 'unit_price_default', 'unit_cost_default', ->
    unit_price = @get('unit_price_default')
    ((unit_price - @get('unit_cost_default')) * 100.0 / unit_price)

  margin: Ember.computed 'unit_price', 'unit_cost', (key, value) ->
    if arguments.length == 1
      unit_price = @get('unit_price')
      ((unit_price - @get('unit_cost')) * 100.0 / unit_price)
    else
      ret = (@get('unit_cost') / (1-parseFloat(value)/100.0))
      ret -= (ret % 0.01)
      @set('unit_price_value', ret)
      value


Ink.DecorationUnspecifiedProps = { id: 0, standard_id: 0, name: 'UN', color: 'white' }
Ink.DecorationColorsController = Ink.DecorationController.extend
  initColors: (->
    @set 'colors', Ember.ArrayProxy.create({content: [ Ember.Object.create(Ink.DecorationUnspecifiedProps) ]})
  ).on('init')

  single: Ember.computed 'colors.@each', ->
    @get('colors.length') == 1

  removeColor: (object) ->
    @get('colors').removeObject object

  count: Ember.computed.alias 'colors.length'

  actions:
    addColor: ->
      @get('colors').addObject Ember.Object.create(Ink.DecorationUnspecifiedProps)


Ink.DecorationColorController = Ember.ObjectController.extend
  styleAttr: Ember.computed 'color', -> Ink.BackgroundStyle(@get('color'))

  single: Ember.computed.alias('parentController.single')

  opened: false

  standardColors: Ember.computed 'parentController.standard_colors', ->
    [Ink.DecorationUnspecifiedProps].concat @get('parentController.standard_colors')

  selectedColor: Ember.computed 'customValue', (key, value) ->
    if value
      @get('model').setProperties(standard_id: value.id, name: value.name, color: value.color)
      value
    else
      id = @get('standard_id')
      @get('standardColors').find (o) -> o.id == id

  customValue: Ember.computed 'selectedColor', (key, value) ->
    if value
      @get('model').setProperties(standard_id: null, name: value, color: 'white')
      value
    else
      return "" if @get('standard_id')?
      @get('name')


  actions:
    open: -> @set('opened', true)
    close: -> @set('opened', false)
    remove: -> @get('parentController').removeColor(@get('model'))


Ink.DecorationNumberController = Ember.Controller.extend()