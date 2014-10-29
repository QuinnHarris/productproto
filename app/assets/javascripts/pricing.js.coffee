class window.PricingBase
  constructor: (@data) ->
  _selectStack: (list, preds) ->
    _.sortBy(
      _.filter(list, (elem) ->
        _.every(elem.predicate, (set) ->
          _.intersection(_.flatten([set]), preds).length > 0
        )
      ),
      (elem) -> -elem.priority)

  _costStack: (predicate) -> @_selectStack(@data.costs, predicate)
  _priceStack: (predicate) -> @_selectStack(@data.costs.concat(@data.prices), predicate)

  variantGroups: (predicate, property) ->
    list = _.clone(@data.properties[property])
    result = []
    until _.isEmpty(list)
      stack = @_priceStack(predicate.concat(list[0].id))
      sub_list = [list.shift()]
      until _.isEmpty(list) ||
            !_.isEqual(stack, @_priceStack(predicate.concat(list[0].id)))
        sub_list.push(list.shift())
      result.push(sub_list)
    return result

class window.PricingInstance extends window.PricingBase
  constructor: (@data) ->
   @variants = []

  setVariantQuantity: (pred, qty) ->
    pred = pred.sort()
    elem = _(@variants).find (elem) ->
      _.isEqual(elem.predicate, pred)
    if elem
      elem.quantity = qty
    else
      @variants.push({ predicate: pred, quantity: qty })

  getQuantity: (predicate = [], exact = false) ->
    _(@variants).filter((elem) ->
      _.difference(predicate, elem.predicate).length == 0 &&
      (!exact || predicate.length == elem.predicate.length)
    ).reduce(((sum, elem) -> sum + elem.quantity), 0)
