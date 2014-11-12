Ink.PropertiesController = Ember.ArrayController.extend
  itemController: 'property'

  #init: ->
  #  @_super()
  #  @get('value')


  value: Ember.computed '@each.property', (key, value) ->
    if value
      for o, i in @
        o.property = value[i]
    else
      @get('@each.property').toArray()


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
