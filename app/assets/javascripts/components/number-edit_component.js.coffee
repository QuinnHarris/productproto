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
    valueDefault = @get('valueDefault')
    return false unless valueDefault?
    value = @get('value')
    if valueDefault == value
      @set('value', null)
      value = null
    value?

  valueComputed: Ember.computed 'value', 'valueDefault', ->
    @get('value') ? @get('valueDefault')

  getFormatedValue: ->
    decimalPlaces = @get('decimalPlaces')
    value = @get('valueComputed')
    return '' unless value?
    value = value.toFixed(decimalPlaces) unless decimalPlaces == -1
    value

  # For internal use
  valueFormated: Ember.computed 'valueComputed', (key, value, old) ->
    if arguments.length == 1
      @getFormatedValue()
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
    @set('valueFormated', @getFormatedValue())
