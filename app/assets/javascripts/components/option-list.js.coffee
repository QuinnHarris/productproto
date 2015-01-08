Ink.ForgroundColor = (color) ->
  m = color.match(/([0-9a-f]{2})/ig)
  return '000000' unless m && m.length == 3
  [r, g, b] = (parseInt(e, 16) for e in m)
  if (r*0.2126 + g*0.7152 + b*0.0722) >= 165
    '000000'
  else
    'FFFFFF'

Ink.BackgroundStyle = (color) ->
  return unless color
  "background-color: #" + color + ";" +
  "color: #" + Ink.ForgroundColor(color) + ";"

Ink.OptionListComponent = Ember.Component.extend
  tagName: 'ul'

  classNames: ['options']

  selected: undefined

  selectedId: Ember.computed 'selected', (key, value) ->
    if arguments.length > 1
      items = @get('items')
      @set('selected', items.find((i) -> i.id == value)) if items
    else
      s = @get('selected')
      s && s.id

  # items property set from outside

  itemsChanged: (->
    return if @get('allowNull')
    items = @get('items')
    return if items.contains(@get('selected'))
    @set('selected', items[0])
  ).observes('items').on('init')


Ink.OptionListItemView = Ember.View.extend
  tagName: 'li'

  classNameBindings: ['selected']
  attributeBindings: ['style']

  style: Ember.computed 'color', -> Ink.BackgroundStyle(@content.color)

  selected: Ember.computed 'parentView.selected', ->
    @content == @get('parentView.selected')

  click: ->
    @set('parentView.selected', @content)
