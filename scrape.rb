require "pdf-reader-turtletext"

file = 'k1.pdf'
reader = PDF::Reader::Turtletext.new(file)
print(reader)

loc = reader.text_position("Part I", 1)
print(loc)


class SchwabScrape

def self.test
	#file = 'D:\RubyData\statements\7053-5344_113016_stmt.pdf'
	#reader = reader(file)
	#orientation = orientation(file)
	#deposits(reader, orientation)
	collect_one(72275957)
end

def self.reader(file)
	PDF::Reader::Turtletext.new(file)
end

def self.page_count(reader, orientation)
	if orientation == "landscape"
		textangle = reader.bounding_box do
		  page 1
		  below /of/i
		  right_of 700
		  below 700
		end
		textangle.text[-1][0].last(2).strip.to_i
	else
		loc = reader.text_position("Number:", 1)
		textangle = reader.bounding_box do
		  page 1
		  right_of loc[:x]
		  above loc[:y] - 50
		  below loc[:y] + 10
		end
		textangle.text[0][2].last(2).strip.to_i
	end
end

def self.account_name(reader, orientation)
	if orientation == "landscape"
		textangle = reader.bounding_box do
		  page 1
		  below /of/i
		  right_of 100
		  left_of 300
		  above 500
		end
		textangle.text.join(" ").gsub('.', '').strip
	else
		loc = reader.text_position("Account Of", 1)
		textangle = reader.bounding_box do
		  page 1
		  right_of 200
		  above 400
		  below 500
		end
		lines = textangle.text[1..-1].count
		textangle.text[1..(lines-2)].join(" ").gsub('.', '').strip
	end
end

def self.account_num(reader, orientation)
	if orientation == "landscape"
		loc = reader.text_position("Account Number", 1)
		textangle = reader.bounding_box do
		  page 1
		  above loc[:y] - 100
		  below loc[:y]
		  right_of loc[:x] - 10
		end
		textangle.text[0][0].gsub('-', '')
	else
		loc = reader.text_position("Number:", 1)
		textangle = reader.bounding_box do
		  page 1
		  right_of loc[:x]
		  above loc[:y] - 50
		  below loc[:y] + 10
		end
		textangle.text[0][0].gsub('-', '')
	end
end

def self.tav_page(reader, orientation)
	if orientation == "landscape"
		if reader.text_position("Change in Account Value", 4).nil? == false
			return 4
		else
			return 2
		end
	else
		return 1
	end
end

def self.end_value(reader, orientation)
	if orientation == "landscape"
		page_num = tav_page(reader, orientation)
		x = reader.text_position("Market Value", page_num)[:x]
		y = reader.text_position("100%", page_num)[:y]
		textangle = reader.bounding_box do
		  page page_num
		  right_of "Total Account Value"
		  left_of x + 100
		  above y - 5
		  below y + 10
		end
		mv = textangle.text[-1][-1].gsub(/\,/,"").to_f
		textangle = reader.bounding_box do
		  page page_num
		  right_of "Total Account Value"
		  left_of x + 50
		  above y - 10
		  below y
		end
		begin
		accrued = textangle.text[-1][-1].gsub(/\,/,"").to_f
			return mv + accrued
		rescue
			return mv
		end	
	else
		textangle = reader.bounding_box do
		  page 1
		  above "Rate"
		  below "Change"
		  right_of "Ending"
		end
		mv = textangle.text[-1][-1].gsub(/\,/,"").to_f
		return mv
	end
end


def self.deposits(reader, orientation)
	if orientation == "landscape"
		page_num = tav_page(reader, orientation)
		x = reader.text_position("Year to Date", page_num)[:x]
		if reader.text_position("Dividends & Interest", page_num).nil? == true
			textangle = reader.bounding_box do
			  page page_num
			  above "Dividends & Interest "
			  below "Investments Purchased/Sold "
			  right_of "Deposits & Withdrawals "
			  left_of x - 50
			end
		else
			textangle = reader.bounding_box do
			  page page_num
			  above "Dividends & Interest"
			  below "Investments Purchased/Sold"
			  right_of "Deposits & Withdrawals"
			  left_of x - 50
			end
		end

		if textangle.text[0][0].include? "("
		-1 * textangle.text[0][0].gsub(/\,/,"").gsub(/\(/,"").gsub(/\)/,"").to_f
		else
		textangle.text[0][0].gsub(/\,/,"").to_f
		end
	else

	end
end

def self.transfers(reader, orientation)
	page_num = tav_page(reader, orientation)
	if reader.text_position("Transfers", page_num).nil? == true
		loc = reader.text_position("Transfers ", page_num)
	else
		loc = reader.text_position("Transfers", page_num)
	end
	x2 = reader.text_position("Year to Date", page_num)[:x]
		textangle = reader.bounding_box do
		  page page_num
		  above loc[:y] - 10
		  below loc[:y] + 10 
		  right_of loc[:x]
		  left_of x2 - 50
		end

	if textangle.text[-1][-1].include? "("
	-1 * textangle.text[-1][-1].gsub(/\,/,"").gsub(/\(/,"").gsub(/\)/,"").to_f
	else
	textangle.text[-1][-1].gsub(/\,/,"").to_f
	end
end

def self.date(reader, orientation)
	if orientation == "landscape"
		loc = reader.text_position("Statement Period", 1)
		textangle = reader.bounding_box do
		  page 1
		  above loc[:y] - 100
		  below loc[:y]
		  right_of loc[:x] - 10
		end
		month = Date::MONTHNAMES.index(textangle.text[0][0].split()[0])
		year = textangle.text[0][0].split()[-1].to_i
		Date.new(year,month,-1)
	else
		loc = reader.text_position("Period:", 1)
		textangle = reader.bounding_box do
		  page 1
		  above loc[:y] - 10
		  below loc[:y] + 10
		  right_of loc[:x] - 10
		end
		month = Date::MONTHNAMES.index(textangle.text[0][-3])
		year = textangle.text[0][-1].to_i
		Date.new(year,month,-1)
	end
end

def self.transactions(reader, orientation, type)
	if orientation == "landscape"
	else
		data = []
		page_num = 0
		page_count(reader,orientation).times do
			page_num += 1
			next if reader.text_position("Transaction", page_num).nil? == true
			next if reader.text_position("Detail", page_num).nil? == true
			textangle = reader.bounding_box do
			  page page_num
			  right_of "Trade"
			  #left_of "Description"
			  #below "Description"
			end
			textangle.text.each do |line|
				#y = reader.text_position(line.first, page_num)[:y]
				type = line[0..1].join(" ").strip
				if type == "Funds Received" or type == "Journaled Funds"
					data.push(type, page_num)
				else end
			end
		end
		return data
	end
end

def self.cash(reader)
	textangle = reader.bounding_box do
	  page 5
	  below "Investment Detail - Cash and Money Market Funds [Sweep]"
	  below "Market Value"
	  above "Total Cash"
	end
	textangle.text[0][-2].gsub(/\,/,"").to_f
end

def self.mm(reader)
	textangle = reader.bounding_box do
	  page 5
	  below "Investment Detail - Cash and Money Market Funds [Sweep]"
	  left_of "Current Yield"
	  right_of "Market Price"
	  below "Money Market Funds [Sweep] "
	  above "Total Money Market Funds [Sweep]"
	end
	textangle.text[0][-1].gsub(/\,/,"").to_f
end

def self.mxl(page, reader)
	text_by_exact_match = reader.text_position("Value", page)[:x]
end

def self.myl(page, reader)
	text_by_exact_match = reader.text_position("Value", page)[:y]
end

def self.value(reader, page)
	x = self.mxl(page,reader)
	y = self.myl(page,reader)
	textangle = reader.bounding_box do
	  page page
	  below y
	  left_of x + 20
	  right_of x - 20
	end
	textangle.text
end

def self.next_sym(y,page,reader)
	textangle = reader.bounding_box do
	  page page
	  below y
	end
	textangle.text.each do |a|
		next if a[0].exclude? 'SYMBOL:'
		return a[0].slice((a[0].index(': ')+2)..-1)
 end
end

def self.statement?(reader)
	textangle = reader.bounding_box do
	  page 1
	end
	textangle.text[0..2].include? "Summary for Enclosed "
end

def self.collect_all
	directory = 'D:\RubyData\statements'
	data = []
	Dir.foreach(directory) do |file|
		next if file.exclude? "pdf"
		next if file.include? "0832-7736"
		#next if file.exclude? "6832-8167"
		path =  directory + "\\" + file
		reader = reader(path)
		orientation = orientation(path)
		puts path
		puts deposits(reader, orientation)
	end
=begin
begin
		SchwabScrape.find_or_create_by(account_num: account_num(reader, orientation),
		 account_name: account_name(reader, orientation),
		 date: date(reader, orientation),
		 end_value: end_value(reader, orientation),
		 deposits: deposits(reader, orientation) + transfers(reader, orientation)
		)
rescue
	puts path
end
	end
=end
end

def self.collect_one(accountnumber)
	begin_time = Time.now
	directory = 'D:\RubyData\statements'
	data = []
	number = accountnumber.to_s[0..3]+"-"+accountnumber.to_s[4..7]
	Dir.foreach(directory) do |file|
		next if file.exclude? "pdf"
		next if file.exclude? number
		path =  directory + "\\" + file
		reader = reader(path)
		orientation = orientation(path)
begin
		SchwabScrape.find_or_create_by(account_num: account_num(reader, orientation),
		 account_name: account_name(reader, orientation),
		 date: date(reader, orientation),
		 end_value: end_value(reader, orientation),
		 deposits: deposits(reader, orientation) + transfers(reader, orientation)
		)
rescue
	puts path
	puts account_num(reader, orientation)
	puts account_name(reader, orientation)
	puts date(reader, orientation)
	puts end_value(reader, orientation)
	puts deposits(reader, orientation)
	puts transfers
end
	end
	end_time = Time.now
	puts "Time elapsed #{(end_time - begin_time).to_i} seconds"
end

def self.unzip_of_zips(file, destination)
  
  FileUtils.mkdir_p(destination)

  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end

  Dir.foreach(destination) do |sub_file|
  	fpath = destination + "\\" + sub_file
  	next if fpath == file
  	next if fpath.exclude? "zip"
  	sub_dest = File.dirname(fpath)
  	unzip(fpath, sub_dest)
  end

end

def self.unzip(file, destination)

	Zip::File.open(file) { |zip_file|
	     zip_file.each { |f|
	     f_path=File.join(destination, f.name)
	     FileUtils.mkdir_p(File.dirname(f_path))
	     zip_file.extract(f, f_path) unless File.exist?(f_path)
	   }
	  }

end

def self.orientation(file)
	page = PDF::Reader.new(file).page(1)
    @orientation ||= detect_orientation(page)
end

def self.detect_orientation(page)
      llx,lly,urx,ury = page.attributes[:MediaBox]
      rotation        = page.attributes[:Rotate].to_i
      width           = urx.to_i - llx.to_i
      height          = ury.to_i - lly.to_i
      if width > height
        [0,180].include?(rotation) ? 'landscape' : 'portrait'
      else
        [0,180].include?(rotation) ? 'portrait' : 'landscape'
      end
    end

end
