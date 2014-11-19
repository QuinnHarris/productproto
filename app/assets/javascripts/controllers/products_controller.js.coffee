Ink.ProductsController = Ember.ObjectController.extend
  #needs: ['properties']

  # propertiesController set in route
  # Seem very kludgy
  propertiesValue: Ember.computed.alias('propertiesController.value')

  variants: Ember.computed ->
    [ { properties: [9] } ]

  theList: Ember.computed ->
    [{ id: null, name: 'Unspec' }].concat @get('properties')[0].list
