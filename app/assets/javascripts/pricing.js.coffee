class window.PricingBase
  constructor: (@data) ->
  _selectStack: (list, preds) ->
    _.sortBy(
      _.filter(list, (elem) ->
        _.every(elem.predicate, (set) ->
          _.intersection(_.flatten([set]), preds).length > 0
        )
      ),
      (elem) -> elem.priority)

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

  _combineBreaks: (meta_list, func) ->
    meta_list = (_.clone(l) for l in meta_list)

    min = _.chain(meta_list).map((l) -> l[0].n).max().value()
    qtys = _.chain(meta_list).map((l) -> _.pluck(l, 'n')).flatten().compact()
            .unique().sort().filter((v) -> v >= min).value()

    for qty in qtys
      for list in meta_list
        list.shift() if list[1] && list[1].n == qty

      { n: qty, v: func.apply(this, (l[0].v for l in meta_list)) }

  _applyStack: (list, predicate, cost_basis = []) ->
    basis = cost_basis
    for elem in @_selectStack(list, predicate)
      meta_list = _.compact([basis, elem.breaks, cost_basis])
      basis = switch elem.op
        when 'add'
          @_combineBreaks meta_list, (a, b) -> a + b
        when 'mult'
          @_combineBreaks meta_list, (a, b) -> a * b
        when 'disc'
          @_combineBreaks meta_list, ((a, b, c) -> (a - c)*b + c)
        else
          elem.breaks
    return basis

  getCostPrice: (predicate) ->
    cost_basis = @_applyStack(@data.costs, predicate)
    price_basis = @_applyStack(@data.prices, predicate, cost_basis)
    { costs: cost_basis, prices: price_basis }


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
