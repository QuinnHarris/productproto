#= require jquery.numeric

Ink.NumberFieldView = Ember.TextField.extend
  negative: true
  decimalPlaces: -1

  didInsertElement: ->
    @_super()
    @$().numeric
      negative: @get('negative')
      decimalPlaces: @get('decimalPlaces')

Ink.NumberEditComponent = Ember.Component.extend
  tagName: 'div'

  classNameBindings: ['changed']

  changed: Ember.computed 'value', ->
    return false unless @get('valueDefault')?
    @get('value')?

  valueComputed: Ember.computed 'value', 'valueDefault', ->
    decimalPlaces = @get('decimalPlaces')
    value = @get('value') ? @get('valueDefault')
    return null unless value?
    value = parseFloat(value)
    return value.toFixed(decimalPlaces) unless decimalPlaces == -1
    value

  # For internal use
  valueFormated: Ember.computed 'valueComputed', (key, value, old) ->
    if arguments.length == 1
      @get('valueComputed') ? ''
    else
      decimalPlaces = @get('decimalPlaces')
      fvalue = parseFloat(value)
      fvalue = fvalue.toFixed(decimalPlaces) unless decimalPlaces == -1
      valueDefault = @get('valueDefault')
      valueDefault = valueDefault.toFixed(decimalPlaces) if valueDefault?
      if fvalue == valueDefault or isNaN(fvalue)
        fvalue = null
      else
        fvalue = parseFloat(fvalue)

      @set('value', fvalue)
      value

  focusIn: ->
    @set('oldValue', @get('valueFormated'))

  focusOut: ->
    @set('valueFormated', @get('valueComputed'))
