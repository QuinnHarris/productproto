Ink.ProductsRoute = Ember.Route.extend
  renderTemplate: ->
    @render 'products'
    @render 'variants', outlet: 'variants', into: 'products'
