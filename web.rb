class Web

require 'rubygems' 
require 'mechanize'
require 'watir' 

def self.test
	browser = start_browser
	login(browser)
	dl_statements(browser,72275957)
end

def self.start_browser
	file_name = nil
	download_directory = 'D:\RubyData\statements'
	download_directory.gsub!("/", "\\") if  Selenium::WebDriver::Platform.windows?
	downloads_before = Dir.entries download_directory

	profile = Selenium::WebDriver::Chrome::Profile.new
	profile['download.prompt_for_download'] = false
	profile['download.default_directory'] = download_directory
	profile['default_content_settings.multiple-automatic-downloads'] = 1

#headless
	#phantom_dir = 'D:\RubyData\pdfscrape\bin'
	#ENV['PATH'] = "#{ENV['PATH']}#{File::PATH_SEPARATOR}#{phantom_dir}"
	#browser = Watir::Browser.new :"phantomjs"
#head
	browser = Watir::Browser.new :chrome, :profile => profile

	browser.goto("https://si2.schwabinstitutional.com/SI2/Home/default.aspx")
	return browser
end

def self.login(browser)
	if browser.li(:class, "logoutLi").exists? == false then
		username = ''
		puts "Input Token Code"
		password = '' + gets 
		browser.text_field(:id, "LogonControl1_txtUser").set(username)
		browser.send_keys :tab 
		browser.text_field(:id, "LogonControl1_txtPass").set(password)
		browser.send_keys :enter
	else end
	puts "Logged in!"
end
	#masters = collect_masters(browser)
	#puts masters
	#dl_statements(browser,40208554)
=begin
	sub_accounts = sub_accounts(browser)
	start_time = Time.now
	sub_accounts.each do |s|
		puts "Collecting : #{s}"
		dl_statements(browser,s)
		puts "Cumulative time running: #{(Time.now - start_time)/60.to_i} minutes"
	end
=end


def self.dl_statements(browser, account_number)
	begin_time = Time.now
	browser.text_field(:id, "TextSearch").wait_until_present(timeout=10)
	browser.text_field(:id, "TextSearch").set(account_number)
	browser.send_keys :enter
	browser.link(:text, "Profiles").wait_until_present(timeout=10)
	browser.link(:text, "Profiles").click
	begin
		browser.span(id: 'ctl00_ContentPlaceHolder1_workArea1_profilesControl_ctl00_accountEstablishedValueLabel').wait_until_present(timeout=10)
		opened = browser.span(id: 'ctl00_ContentPlaceHolder1_workArea1_profilesControl_ctl00_accountEstablishedValueLabel').text[-4..-1].to_i
	rescue
		browser.link(:text, "Profiles").click
		browser.span(id: 'ctl00_ContentPlaceHolder1_workArea1_profilesControl_ctl00_accountEstablishedValueLabel').wait_until_present(timeout=10)
		opened = browser.span(id: 'ctl00_ContentPlaceHolder1_workArea1_profilesControl_ctl00_accountEstablishedValueLabel').text[-4..-1].to_i
	end
	browser.link(:text, "Documents").wait_until_present(timeout=10)
	browser.link(:text, "Documents").click
	browser.text_field(name: "ctl00_ContentPlaceHolder1_workArea1_documentsControl_ctl00_pickerFromDocuments_picker").wait_until_present(timeout=10)

	year = Date.today.last_month.year
	11.times do |y|
		next if year < opened
		field = browser.input(name: 'ctl00_ContentPlaceHolder1_workArea1_documentsControl_ctl00_pickerFromDocuments_picker')
		count = 0
		while field.value != "" && count < 50
		  field.send_keys(:backspace)
		  count += 1
		end
		field.send_keys "1/1/#{year}"

		field = browser.input(name: 'ctl00_ContentPlaceHolder1_workArea1_documentsControl_ctl00_pickerToDocuments_picker')
		count = 0
		while field.value != "" && count < 50
		  field.send_keys(:backspace)
		  count += 1
		end
		field.send_keys "12/31/#{year}"
		browser.send_keys :enter
		begin
			begin
				browser.link(text: "Monthly Statement - January").wait_until_present(timeout=5)
				links = browser.link(text: "Monthly Statement - January").parent.parent.parent.links
			rescue
				browser.link(text: "Monthly Statement - December").wait_until_present(timeout=5)
				links = browser.link(text: "Monthly Statement - December").parent.parent.parent.links
			end
		rescue
			year = year -1
			break
		end
		links.each do | link | 
			next if link.text.include? "Summary"
		    browser.link(text: link.text).click
		end
		year = year -1
	end
	end_time = Time.now
	puts "Time elapsed #{(end_time - begin_time).to_i} seconds"
end

def self.collect_masters(browser)
	master_links = []
	browser.span(:id, 'ctl00_ContentPlaceHolder1_switcher1_MasterHeaderLabel').parent.parent.tables.first.wait_until_present
	master_table = browser.span(:id, 'ctl00_ContentPlaceHolder1_switcher1_MasterHeaderLabel').parent.parent.tables.first
	master_count = master_table.rows.length
	row = 0
	master_count.times do
		master_links.push(master_table[row].text[0..8].gsub('-', ''))
		row = row + 1
	end
	return master_links
end

def self.sub_accounts(browser)
	browser.link(:text, 'CIRCLE WEALTH MANAGEMENT LLC').wait_until_present(timeout=10)
	browser.link(:text, 'CIRCLE WEALTH MANAGEMENT LLC').click
	master_links = []
	browser.span(:id, 'ctl00_ContentPlaceHolder1_switcher1_MasterHeaderLabel').parent.parent.tables.first.wait_until_present
	master_table = browser.span(:id, 'ctl00_ContentPlaceHolder1_switcher1_MasterHeaderLabel').parent.parent.tables.first
	master_count = master_table.rows.length
	puts "Master count = #{master_count}"
	accounts = []
	master_table.rows.each do |row|
		browser.link(:text, 'CIRCLE WEALTH MANAGEMENT LLC').wait_until_present(timeout=10)
		browser.link(:text, 'CIRCLE WEALTH MANAGEMENT LLC').click
		next if row[-1].text == '(0)'
		puts "Row link = #{row.link.text}"
		browser.link(:text, row.link.text).wait_until_present(timeout=10)
		browser.link(:text, row.link.text).click
		browser.link(:text, "Balances").wait_until_present(timeout=10)
		browser.link(:text, "Balances").click
		browser.div(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid_dom').wait_until_present
		row_count = browser.div(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid_dom').tables.first.rows.count
		total = browser.div(:id, 'balances_RowResults').text[-3..-1].gsub(/[^0-9,.]/, "").to_i
		puts total
		if total > 100 then
			browser.div(:id, 'balances_PagerNav_Top').wait_until_present(timeout = 5)
			pages = browser.div(:id, 'balances_PagerNav_Top').spans[1].text.to_i - 1
		else
			pages = 0
		end
		puts "Pages = #{pages}"
		for k in 0..pages
			puts k
			browser.div(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid_dom').tables.first.rows[1..-1].each do |a_row|
				num = a_row[0].text.gsub('-', '')
				accounts.push(num)
				puts num
			end
			if k < pages then
				browser.div(:id, 'balances_PagerNav_Top').links[1].click
			else end
		end
		puts "Account count = #{accounts.count}"
	end
	return accounts
end

=begin
#reset to main page

	browser.link(:id, "ctl00_ContentPlaceHolder1_switcher1_FirmLink").wait_until_present
	browser.link(:id, "ctl00_ContentPlaceHolder1_switcher1_FirmLink").click

#collect master links

	master_links = Array.new
	master_table = browser.div(:id, 'ctl00_ContentPlaceHolder1_switcher1_AssociatedItems').tables.first.wait_until_present
	master_table = browser.div(:id, 'ctl00_ContentPlaceHolder1_switcher1_AssociatedItems').tables.first
	master_count = master_table.rows.length
	for k in 0..master_count-1
		master_links.push(master_table[k][0])
	end

#visit first master

	browser.link(:text, master_links.first.to_s).click
	browser.link(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesTab').wait_until_present
	browser.link(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesTab').click

#collect individual account numbers

	browser.div(:id, "balances_PagerNav_Top").wait_until_present
	page_count = browser.div(:id, "balances_PagerNav_Top").spans[1].text.to_i-1
	
	account_array = Array.new

	page_count.times do
		browser.table(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid').tables.first.wait_until_present
		account_table = browser.table(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid').tables.first
		account_row_count = account_table.rows.length
		for k in 1..account_row_count-1
		    account_array.push(
		    				[account_table[k][0].text.delete("-"),
		    				 account_table[k][2].text.to_f,
		    				 account_table[k][3].text.to_f,
		    				]
		    				)
		end
		browser.link(:class, "nextPage").click
	end

		browser.table(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid').tables.first.wait_until_present
		account_table = browser.table(:id, 'ctl00_ContentPlaceHolder1_workArea1_balancesControl_ctl00_brokerageBalance_BrokerageGroupGrid').tables.first
		account_row_count = account_table.rows.length
		for k in 1..account_row_count-1
		    account_array.push(
		    				[account_table[k][0].text.delete("-"),
		    				 account_table[k][2].text.to_f,
		    				 account_table[k][3].text.to_f,
		    				]
		    				)
		end

#define position array

	table_array = Array.new

#visit accounts

	browser.li(:text, "Cost Basis").wait_until_present(timeout=5)
	if browser.li(:text, "Cost Basis").class_name == ""
		browser.link(:text, "Cost Basis").click
	else end

	account_array[0..5].each do |account|

		browser.text_field(:id, "TextSearch").wait_until_present(timeout=5)
		browser.text_field(:id, "TextSearch").set(account.first)
		browser.send_keys :enter		

#collect position-level detail
		tries = 0
		begin
  
		browser.link(:id, 'ctl00_ContentPlaceHolder1_workArea1_costbasisControl_ctl01_realizedgainlossTab').wait_until_present(timeout=5)
		browser.link(:class, 'ExpandLots0').wait_until_present(timeout=5)
		browser.table(:id, 'ctl00_ContentPlaceHolder1_workArea1_costbasisControl_ctl01_UnrealizedGainLoss_uglGrid').tables.first.wait_until_present(timeout=5)
		table = browser.table(:id, 'ctl00_ContentPlaceHolder1_workArea1_costbasisControl_ctl01_UnrealizedGainLoss_uglGrid').tables.first
		browser.span(:id, 'ctl00_ContentPlaceHolder1_workArea1_costbasisControl_ctl01_TabHeader_lblContextId').wait_until_present(timeout=5)
		row_count = table.rows.length

		rescue 
			tries += 1
			retry if tries <=2
		end

			if browser.link(:class, 'ExpandLots0').exists? == false then next else

				for k in 1..row_count-1
				    table_array.push(
				    				[account.first,
				    				table[k][1].text,
				    				table[k][4].text,
				    				table[k][5].text,
				    				table[k][6].text]
				    				)
		 	end
		end
	end

puts table_array
=end
end