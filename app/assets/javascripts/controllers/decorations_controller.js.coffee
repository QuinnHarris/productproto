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


Ink.DecorationColorsController = Ember.ObjectController.extend()