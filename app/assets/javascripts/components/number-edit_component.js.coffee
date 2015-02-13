#= require jquery.numeric

Ink.NumberFieldView = Ember.TextField.extend
  negative: true
  #decimalPlaces: -1

  didInsertElement: ->
    @_super()
    @$().numeric
      negative: @get('negative')
      decimalPlaces: @get('decimalPlaces')

Ink.NumberEditComponent = Ember.Component.extend
  tagName: 'div'

  classNameBindings: ['changed']

  changed: Ember.computed 'value', 'valueDefault', ->
    return false if @get('noNull')?
    valueDefault = @get('valueDefault')
    return false unless valueDefault?
    value = @get('value')
    if valueDefault == value
      @set('value', value = null)
    value?

  valueComputed: Ember.computed 'value', 'valueDefault', ->
    value = @get('value') ? @get('valueDefault')
    return null if value == ''
    value

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
      valueDefault = @get('valueDefault')
      noNull = @get('noNull')

      fvalue = parseFloat(value)
      if isNaN(fvalue)
        if noNull?
          fvalue = valueDefault
        else
          fvalue = null
      else
        unless noNull?
          valueDefaultS = valueDefault.toFixed(decimalPlaces) if valueDefault?
          fvalueS = fvalue.toFixed(decimalPlaces) unless decimalPlaces == -1
          if fvalueS == valueDefaultS
            fvalue = null

      @set('value', fvalue)
      value

  focusOut: ->
    fv = @getFormatedValue()
    if @get('valueFormated') != fv
      @set('valueFormated', fv)
