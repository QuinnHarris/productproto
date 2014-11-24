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

  classNameBindings: ['changed']

  changed: Ember.computed 'value', ->
    return false unless @get('valueDefault')?
    @get('value')?

  valueFormated: Ember.computed 'value', 'valueDefault', (key, value) ->
    decimalPlaces = @get('decimalPlaces')
    if value
      fvalue = parseFloat(value)
      valueDefault = @get('valueDefault')
      if fvalue == valueDefault
        fvalue = null
      else
        fvalue = fvalue.toFixed(decimalPlaces) unless decimalPlaces == -1

      @set('value', fvalue)
      value
    else
      value = @get('value')
      value = @get('valueDefault') unless value?
      value = parseFloat(value)
      return "" if isNaN(value)
      return value.toFixed(decimalPlaces) unless decimalPlaces == -1
      value

  focusOut: ->
    @set('valueFormated', @get('value'))
