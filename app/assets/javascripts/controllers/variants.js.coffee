Ink.VariantsController = Ember.Controller.extend
  variants: [
    {quantity: 105, unit_price: 3.15, unit_cost: 2.15},
    {quantity: 205, unit_price: 4.15, unit_cost: 3.15},
  ]

Ink.VariantController = Ember.ObjectController.extend
  needs: 'variants'
  #quantity: 100
  #unit_price: 2.15
  total_price: Ember.computed 'quantity', 'unit_price', ->
    @get('quantity') * @get('unit_price')

  #unit_cost: 1.85
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


