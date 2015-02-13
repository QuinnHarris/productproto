#= require_self

window.Ink = Ember.Application.create
  LOG_TRANSITIONS: true


# Should implement in didInsertElement on relevant items but having problems doing it
# Make div.overflow elements in table th overflow to the right of table
# and size th to height of the content of the div
setOverflow = ->
  $('tr > th > div.overflow').each ->
    elem = $(@)
    th = elem.parent()
    elem.width(th.parent().width() - elem.position().left)
    th.height(elem.height())

$(window).resize setOverflow

Ember.View.reopen({
  didInsertElement: ->
    @_super();
    Ember.run.scheduleOnce('afterRender', @, @afterRenderEvent);

  afterRenderEvent: setOverflow
});
