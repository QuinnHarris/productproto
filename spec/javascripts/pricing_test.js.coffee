#= require application
#= require pricing

describe "Pricing", ->
  beforeEach ->
    @pricing = new window.PricingInstance({"properties":{"colors":[{"id":9,"name":"Ash"},{"id":10,"name":"Black"},{"id":11,"name":"Cardinal Red"},{"id":12,"name":"Carolina Blue"},{"id":13,"name":"Charcoal"},{"id":14,"name":"Dark Chocolate"},{"id":15,"name":"Dark Heather"},{"id":16,"name":"Forest Green"},{"id":17,"name":"Indigo Blue"},{"id":18,"name":"Light Blue"},{"id":19,"name":"Maroon"},{"id":20,"name":"Natural"},{"id":21,"name":"Navy"},{"id":22,"name":"Orange"},{"id":23,"name":"Prairie Dust"},{"id":24,"name":"Purple"},{"id":25,"name":"Red"},{"id":26,"name":"Royal"},{"id":27,"name":"Sand"},{"id":28,"name":"Sport Grey"},{"id":29,"name":"White"},{"id":30,"name":"Yellow Haze"},{"id":31,"name":"Kiwi"},{"id":32,"name":"Prairie Dust"}],"sizes":[{"id":1,"name":"S"},{"id":2,"name":"M"},{"id":3,"name":"L"},{"id":4,"name":"XL"},{"id":5,"name":"2XL"},{"id":6,"name":"3XL"},{"id":7,"name":"4XL"},{"id":8,"name":"5XL"}]},"locations":[{"id":34,"name":"Front"},{"id":35,"name":"Back"}],"techniques":[{"id":36,"name":"Screen Print"},{"id":37,"name":"Photo Print"}],"decorations":[{"id":38,"location":34,"technique":36},{"id":39,"location":34,"technique":37},{"id":40,"location":35,"technique":36},{"id":41,"location":35,"technique":37}],"costs":[{"predicate":[[1,2,3,4]],"priority":0,"basis":1,"breaks":[[1,7.5],[12,6.32],[72,5.47]]},{"predicate":[5],"priority":0,"basis":1,"breaks":[[1,9.73],[12,8.21],[72,7.1]]},{"predicate":[6],"priority":0,"basis":1,"breaks":[[1,10.24],[12,8.57],[72,7.37]]},{"predicate":[7],"priority":0,"basis":1,"breaks":[[1,10.44],[12,8.7],[72,7.47]]},{"predicate":[8],"priority":0,"basis":1,"breaks":[[1,10.83],[12,8.98],[72,7.67]]},{"predicate":[[9,28],[1,2,3,4]],"priority":1,"basis":1,"breaks":[[1,7.1],[12,5.98],[72,5.17]]},{"predicate":[[9,28],5],"priority":1,"basis":1,"breaks":[[1,9.13],[12,7.69],[72,6.65]]},{"predicate":[[9,28],6],"priority":1,"basis":1,"breaks":[[1,9.63],[12,8.04],[72,6.91]]},{"predicate":[[9,28],7],"priority":1,"basis":1,"breaks":[[1,9.8],[12,8.16],[72,7.0]]},{"predicate":[[9,28],8],"priority":1,"basis":1,"breaks":[[1,10.1],[12,8.42],[72,7.19]]},{"predicate":[[30,31,32]],"priority":1,"breaks":[[1,1.64]]},{"predicate":[30,6],"discontinued":true}],"prices":[{"priority":10,"op":"mult","breaks":[{"marginal":1.3}]},{"predicate":36,"priority":20,"op":"add","basis":2,"breaks":[[10,50.0]]},{"predicate":36,"priority":20,"op":"add","basis":3,"breaks":[[10,0.5]]},{"predicate":37,"priority":20,"op":"add","basis":3,"breaks":[[1,1.5]]},{"predicate":33,"priority":20,"op":"add","breaks":[{"fixed":20.0}]}]})

  describe "Base", ->
    it "provide variant groups", ->
      result = @pricing.variantGroups([9], 'sizes')
      expect(result).to.have.length(5)
      expect(result[0]).to.have.length(4)
      for sub in result[1..5]
        expect(sub).to.have.length(1)

  describe "Instance", ->
    it "set and get a variant quantity", ->
      @pricing.setVariantQuantity([9], 10) # Ash, no size
      expect(@pricing.getQuantity()).to.equal(10)
      expect(@pricing.getQuantity([9])).to.equal(10)
      expect(@pricing.getQuantity([10])).to.equal(0)

      @pricing.setVariantQuantity([1, 9], 5) # Ash
      expect(@pricing.getQuantity()).to.equal(15)
      expect(@pricing.getQuantity([9])).to.equal(15)
      expect(@pricing.getQuantity([9], true)).to.equal(10)
      expect(@pricing.getQuantity([1])).to.equal(5)
      expect(@pricing.getQuantity([10])).to.equal(0)

      @pricing.setVariantQuantity([9], 0) # Ash, no size
      expect(@pricing.getQuantity()).to.equal(5)
      expect(@pricing.getQuantity([9])).to.equal(5)
      expect(@pricing.getQuantity([9], true)).to.equal(0)
