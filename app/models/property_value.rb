class PropertyValue < Variable
  private
  attr_writer :previous
  public
  def persisted?
    !@previous.nil? || super
  end

  def new(new_values = {})
    vals = values.dup
    vals.delete(:created_at)
    vals.merge!(new_values)

    o = self.class.new(new_values)
    o.send(:set_restricted, { link_key => values[link_key] }, [link_key])
    o.send('previous=', self)
    o.changed_columns.clear
    yield o if block_given?
    o
  end

  def create(values = {}, &block)
    new(values, &block).save
  end
end
