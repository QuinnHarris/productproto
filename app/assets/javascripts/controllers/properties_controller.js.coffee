Ink.PropertiesController = Ember.ArrayController.extend
  itemController: 'property'

  #init: ->
  #  @_super()
  #  @get('value')


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
    [{ id: null, name: 'Unspec' }].concat @get('list')

Ink.OptionController = Ember.ObjectController.extend
  selected: Ember.computed 'parentController.property', ->
    @get('parentController.property') == @get('id')

  actions:
    select: ->
      @set('parentController.property', @get('id'))
      #@get('parentController.parentController.value')