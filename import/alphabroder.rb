require_relative 'import'
require 'csv'

class AlphaBroderImport < GenericImport
  def initialize
    @src_directory = '/home/quinn/promoweb/jobs/data/alphabroder'
    super
  end

  def CSV_foreach(file, &block)
    CSV.foreach(File.join(@src_directory, file), encoding: "ISO-8859-1", headers: :first_row, &block)
  end

  def define_schema
    super

    feature_keys = {}
    feature_map_cols = %w(product-code feature-code)
    CSV_foreach('features.csv') do |row|
      feature_keys[feature_map_cols.map { |c| row[c] }] = row['description']
    end

    property_values = {}
    CSV_foreach('feature-details.csv') do |row|
      keys = feature_map_cols.map { |c| row[c] }
      if keys.find { |k| k.blank? }
        warning "Unexpected Style Feature".freeze, keys
        next
      end
      feature_key = feature_keys[keys]

      value_set = (property_values[feature_key] ||= Set.new)
      value_set << row['description']
    end
    yes_no_set = Set.new(['Yes', 'No'])
    property_values.each do |prop, set|
      blank = set.delete?('')
      if set == yes_no_set
        type = :boolean
      else
        type = :natural
      end

      if d.apply_property(prop, type)
        puts "#{prop} (#{type}#{blank && '*'}): #{set.to_a.inspect}"
      end
    end
  end

  def define_data
    puts "Start"
    feature_map_cols = %w(product-code feature-code)
    property_map = {}
    CSV_foreach('features.csv') do |row|
      property_map[feature_map_cols.map { |c| row[c] }] = d.find_property(row['description'])
    end

    @style_values = {}
    CSV_foreach('style-features.csv') do |row|
      next if row['description'].blank?
      keys = feature_map_cols.map { |c| row[c] }
      if keys.find { |k| k.blank? }
        @supplier_num = row['style-code']
        warning "Unexpected Style Feature", keys
        next
      end
      property = property_map[keys]
      raise "Unknown feature: #{row['style-code']}: #{row['product-code']}, #{row['feature-code']}" unless property

      values = (@style_values[row['style-code']] ||= [])
      values << property.get_value(row['description'])
    end

    puts "Load Items"
    @items = {}
    CSV_foreach('items_R064.csv') do |row|
      items = (@items[row['Style Code']] ||= [])
      items << row
    end

    puts "Main Loop"
    CSV_foreach('styles.csv') do |row|
      next if row['Category Code'] == 'EMB'

      #puts "Product: #{row['Style Code']}"
      pd = d.get_product(row['Style Code'])
      pd.set_value('SKU', row['Style Code'])
      pd.set_value('name', row['Description'])

      pd.set_implies(@style_values[row['Style Code']]) if @style_values[row['Style Code']]
    end
  end
end