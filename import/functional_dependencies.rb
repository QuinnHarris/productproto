require 'csv'

def find_dependents(file)
  puts "Loading"
  list = []
  headers = nil
  CSV.open(file, encoding: "ISO-8859-1") do |csv|
    #csv.each { |r| list << r }
    headers, *list = csv.to_a
  end


  #exclude_common = %w(Company Domain Coming\ Soon Description)
  exclude_common = headers.find_all { |h| !["Item Number", "GTIN Number", "Size Name", "Color Name", "Style Number"].include?(h) }
  exclude_headers = exclude_common #+ %w(Item\ Number)
  exclude_dependent = exclude_common

  sequence_base = (0...headers.length).find_all { |i| !exclude_dependent.include?(headers[i]) }

  @dependency_map = {}
  @forward_dependency_map = {}

  duplicates = {}

  begin
    (1..4).each do |count|
      puts "Pass #{count}"
      headers.each_with_index do |name, index|
        next if exclude_headers.include?(name)
        next if duplicates.keys.include?(index)
        print "#{name}:"

        dependents = (sequence_base - [index]).permutation(count).map { |a| a.sort }.uniq

        if @dependency_map[index]
          dependents.delete_if { |a| @dependency_map[index].find { |e| (e-a).empty? } }
        end

        @dependency_map[index] ||= []


        puts " #{dependents.length}"


        #puts "Pass: #{full_dependents}"

        until dependents.empty?
          set = dependents.pop

          value_map = {}
          match = !list.find.with_index do |row, j|
            current = row[index]
            reference = set.map { |i| row[i] }

            if prev = value_map[reference]
              if current != prev
                puts " - #{set.map { |i| headers[i]}}: #{current} != #{prev} for #{reference} @ #{j}"
                next true;
              end
            else
              value_map[reference] = current
            end
            false
          end
          if match
#              dependents.delete_if do |dep|
#                (0...dep.length).each do |i|
#
#                end
#                @forward_dependency_map.find do |s, list|
#                  if (s - dep).empty?
#                    common = dep - set
#                    list.map { |e| (common + [e]).uniq.sort } == set
#                  end
#                  false
#                end
#              end

            @dependency_map[index] << set
            @forward_dependency_map[set] ||= []
            @forward_dependency_map[set] << index
          end
        end

        puts "  #{@dependency_map[index].map { |a| a.map { |i| headers[i] }}}" if @dependency_map[index]
      end
    end
  ensure

    puts "Result:"
    duplicates.each do |src, dup|
      puts "  #{headers[src]} <=> #{headers[dup]}"
    end
    @dependency_map.each do |index, list|
      puts "  #{headers[index]} <= #{list.map { |a| a.map { |i| headers[i] }}}"
    end
    puts "Final:"
    @forward_dependency_map.each do |set, list|
      puts "  #{set.map { |i| headers[i] }} => #{list.map { |i| headers[i] }}"
    end
  end

end

@src_directory = '/home/quinn/promoweb/jobs/data/alphabroder'
find_dependents(File.join(@src_directory, 'items_R064.csv'))