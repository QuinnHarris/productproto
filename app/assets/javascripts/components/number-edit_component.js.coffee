#= require jquery.numeric

Ink.NumberFieldView = Ember.TextField.extend
  negative: true
  decimalPlaces: -1

  didInsertElement: ->
    $(@element).numeric
      negative: @get('negative')
      decimalPlaces: @get('decimalPlaces')

Ink.NumberEditComponent = Ember.Component.extend
  tagName: 'div'

  valueFormated: Ember.computed 'value', (key, value) ->
    decimalPlaces = @get('decimalPlaces')
    if value
      value = parseFloat(value).toFixed(decimalPlaces) unless decimalPlaces == -1
      @set('value', value)
    else
      value = parseFloat(@get('value'))
      return "" if isNaN(value)
      return value.toFixed(decimalPlaces) unless decimalPlaces == -1
      value
