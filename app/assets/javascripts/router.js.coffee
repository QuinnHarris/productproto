# For more information see: http://emberjs.com/guides/routing/

Ink.Router.map ()->
  @resource 'products'

Ink.Router.reopen
  location: 'history'  # or auto
