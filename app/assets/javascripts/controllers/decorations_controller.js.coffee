Ink.DecorationsController = Ember.ObjectController.extend
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


Ink.DecorationUnspecifiedProps = { id: 0, standard_id: 0, name: 'UN', color: 'white' }
Ink.DecorationColorsController = Ember.ObjectController.extend
  initColors: (->
    @set 'colors', Ember.ArrayProxy.create({content: [ Ember.Object.create(Ink.DecorationUnspecifiedProps) ]})
  ).on('init')

  single: Ember.computed 'colors.@each', ->
    @get('colors.length') == 1

  removeColor: (object) ->
    @get('colors').removeObject object

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