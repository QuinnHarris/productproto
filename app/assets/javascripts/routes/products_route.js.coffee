Ink.ProductsRoute = Ember.Route.extend
  model: ->
    this.store.find('instance', 1)

  renderTemplate: (controller, model) ->
    @render 'products',
      controller: controller,
      model: product_data.data

    properties_controller = this.controllerFor('properties')
    controller.set('propertiesController', properties_controller)
    @render 'properties',
      controller: properties_controller,
      outlet: 'properties',
      into: 'products',
      model: product_data.data.properties

    variants_controller = this.controllerFor('variants')
    variants_controller.set('propertiesController', properties_controller)
    @render 'variants',
      controller: variants_controller,
      outlet: 'groups',
      into: 'products',
      model: model,
      product_data: product_data.data


    @render 'decorations',
      outlet: 'decorations',
      into: 'products',
      model: product_data.data
