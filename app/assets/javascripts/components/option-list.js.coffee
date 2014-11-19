Ink.OptionListComponent = Ember.Component.extend
  tagName: 'ul'

  selected: undefined

  selectedId: Ember.computed 'selected', (key, value) ->
    if value
      @set('selected', @get('items').find((i) -> i.id == value))
    else
      s = @get('selected')
      s && s.id

  # items property set from outside

  itemsChanged: (->
    items = @get('items')
    return if items.contains(@get('selected'))
    @set('selected', items[0])
  ).observes('items').on('init')


Ink.OptionListItemView = Ember.View.extend
  tagName: 'li'

  classNameBindings: ['selected']

  selected: Ember.computed 'parentView.selected', ->
    @content == @get('parentView.selected')

  click: ->
    @set('parentView.selected', @content)
