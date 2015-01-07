require_relative 'common'

b_ds = Business.where(id: BusinessEmail.select(:business_id) ).invert


b_ds.paged_each do |business|

end

