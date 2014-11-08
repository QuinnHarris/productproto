Ink.ProductsRoute = Ember.Route.extend
  renderTemplate: ->
    @render 'products'
    @render 'variantGroups', outlet: 'groups', into: 'products'
