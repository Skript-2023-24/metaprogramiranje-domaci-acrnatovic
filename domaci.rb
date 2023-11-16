 require 'google_drive'

 class Lib 
   include Enumerable
   attr_reader :worksheet, :header
    def initialize (session, spreadsheet_key, options = {})
        @session = session
        @spreadsheet = session.spreadsheet_by_key(spreadsheet_key)
        @worksheet = @spreadsheet.worksheets[0]
        @content_cells = load_content_cells
        @header = find_header
        define_column_methods
    end

    def load_content_cells
     @worksheet.rows.reject(&:empty?)
    end

    def find_header
      @content_cells.drop(2).find {|row| !row.compact.empty?}
    end

    def define_column_methods
      return if @header.nil?
      @header.each do |column_name|
        next if column_name.to_s.strip.empty?
        method_name = column_name.gsub(/\s+/, '').to_sym
        define_singleton_method(method_name) {self[column_name]}
        define_singleton_method("#{method_name}.sum") { ColumnAccessor.new(self, @header.find_index(column_name), self[column_name]).sum }
        define_singleton_method("#{method_name}.avg") { ColumnAccessor.new(self, @header.find_index(column_name), self[column_name]).avg }
      end
    end

  def array
    @content_cells.reject{|row| row.all?(&:empty?) || row.any?{|cell|cell.to_s.downcase.include?('total') || cell.to_s.downcase.include?('subtotal')}}
                  .each {|row| puts row.inspect}
  end

 def row(index)
    raise ArgumentError, "Pogresan unos indeksa." unless (0..@content_cells.length - 1).cover?(index)
    non_empty_rows = @content_cells.reject { |row| row.all?(&:nil?) || row.all?(&:empty?) }
    row_format = non_empty_rows [index].map { |cell| cell.to_s}
    puts "Vrednost reda: #{row_format.join(',')}"
 end


  def each(&block)
  @content_cells.flatten.each {|cell| puts cell.to_s.strip unless cell.to_s.strip.empty?}
  end

  def merged(row,col)
    merged_ranges = @worksheet.merged_ranges
    merged_ranges.any? {|range| range.include?(row,col)}
  end

  def [] (column_name)
    header = @content_cells[2].compact
    raise ArgumentError, "Tabela nema header" if header.empty?
   
   column_index = header.map(&:downcase).index(column_name.downcase)
   raise ArgumentError, "Pogresan naziv kolone: #{column_name.inspect}" if column_index.nil?

   values = @content_cells[1..].map{|row| row[column_index].to_s }.reject(&:empty?)
   puts "Vrednosti u koloni #{column_name}: #{values.drop(1)}" 
    ColumnAccessor.new(self,column_index, values)
  end
  
  def empty
    empty_rows = @content_cells.select {|row| row.all?(&:empty?)}
    if empty_rows.each do |empty_row|
      puts "Identifikovan prazan red"
    end
  end

end

end
   class ColumnAccessor 
   def initialize(lib, column_index, values)
    @lib = lib
    @column_index = column_index
    @values = values
   end

    def [] (index)
    non_empty_values = @values.map {|value| value.to_s}.reject(&:empty?)
    return nil if index < 0 || index >= non_empty_values.length
    puts "Vrednosti u koloni :#{non_empty_values.drop(1)}"
    non_empty_values[index].tap {|value| puts "Vrednost trazenog elementa: #{value}"}
    end  

    
    def to_a
      non_empty_values = @values.map {|value| value.to_s}.reject(&:empty?)
      non_empty_values
    end

    def to_s
     "#{values.join(',')} (Sum: #{sum}, Avg: #{avg})"
    end

  def sum 
    @values.map(&:to_i).sum
  end

  def avg 
    total = @values.drop(1).map(&:to_i).sum 
    total/ (@values.length - 1).to_f
  end

  def map (&block)
    @values.drop(1).map {|value| block.call(value.to_s)}
  end

  def select(&block)
    @values.drop(1).select {|value| block.call(value.to_s)}
  end

  def reduce(initial = 0, &block)
    @values.drop(1).map(&:to_i).reduce(&block)
  end

end

def main(t) 
session = GoogleDrive::Session.from_config('config.json')


#sve metode su zakomentarisane radi lakseg snalazenja sa outputima jedne po jedne metode
      #1. VREDNOSTI TABELE
      #t.array

      #2. VREDNOSTI IZ REDA
      #t.row(1);

      #3. EACH-SVE VREDNOSTI CELIJA
     # t.each

      #5.a) VREDNOST CELE KOLONE
      #t["Prva Kolona"]
      #b) VREDNOSTI UNUTAR KOLONE
      #t["Prva Kolona"][2] 

      #6.a) DIRKETNI PRISTUP KOLONAMA
      #t.PrvaKolona
      #t.DrugaKolona
      #t.TrecaKolona
    
      #6.i) T.PRVAKOLONA.SUM I T.PRVAKOLONA.AVG
      #p t.PrvaKolona.sum
      #p t.TrecaKolona.avg

      #6.iii) MAP,
      #p t.PrvaKolona.map {|cell| cell.to_i+1}
      #SELECT,
      #p t.TrecaKolona.select {|cell| cell.to_i > 4}
      #REDUCE
      #p t.TrecaKolona.reduce {|acc,value| acc+value.to_i}

      #7. TOTAL, SUBTOTAL
      #IGNORISE TOTAL, SUBTOTAL PRI ISCITAVANJU
      #new_row = [nil, 'total','23', 'subtotal']
      #worksheet = t.worksheet
      #worksheet.insert_rows(worksheet.num_rows + 1,[new_row]) 
      #worksheet.save
      #t = Lib.new(session, '1XOs2NEHYT_3xOFG3w3L9b9zyx3wzxQYtIWHOdT8n2sw')
      #t.array
      #ISPISUJE NOVI RED KADA NE SADRZI TOTAL, SUBTOTAL
      #new_row = [nil, 'blabla','truc', '9']
      #worksheet = t.worksheet
      #worksheet.insert_rows(worksheet.num_rows + 1,[new_row]) 
      #worksheet.save
      #t = Lib.new(session, '1XOs2NEHYT_3xOFG3w3L9b9zyx3wzxQYtIWHOdT8n2sw')
      #t.array

      #10. PREPOZNAVANJE PRAZNIH REDOVA
      #t.empty

    end

 session = GoogleDrive::Session.from_config('config.json')
 t = Lib.new(session, '1XOs2NEHYT_3xOFG3w3L9b9zyx3wzxQYtIWHOdT8n2sw')
 main(t)
