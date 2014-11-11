Ink.PropertiesController = Ember.ArrayController.extend
  itemController: 'property'

  value: Ember.computed '@each.property', (key, value) ->
    if value
      for o, i in @
        o.property = value[i]
    else
      @get('@each.property').toArray()

  #valueBinding: 'parentController.thatthing'

  #testit: Ember.computed.alias('parentController.thatthing')
  anotherBinding: 'parentController.thatthing'

  #thatthingBinding: 'parentController.thatthing'

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
