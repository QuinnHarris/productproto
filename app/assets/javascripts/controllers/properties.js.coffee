Ink.PropertiesController = Ember.ArrayController.extend
  itemController: 'property'
  #model:  [{name: 'colors', model: product_data.data.properties.colors}]

  testprop: Ember.computed ->
    "test prop"


Ink.PropertyController = Ember.ObjectController.extend()
