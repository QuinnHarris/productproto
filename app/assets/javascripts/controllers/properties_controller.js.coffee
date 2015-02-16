Ink.PropertiesController = Ember.ArrayController.extend
  itemController: 'property'

  value: Ember.computed '@each.property', (key, value) ->
    if value
      for o, i in @_subControllers
        o.set('property', value[i])
    @get('@each.property').toArray()

  availableIds: Ember.computed ->
    @get('@each.fullList').map (l) -> l.mapBy('id')


Ink.PropertyController = Ember.ObjectController.extend
  property: null

  fullList: Ember.computed ->
    [{ id: null, name: 'Not Specified' }].concat @get('list')
