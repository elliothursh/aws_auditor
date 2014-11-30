require 'google_drive'

module AwsAuditor
	class GoogleSheet
		extend GoogleWrapper

		attr_accessor :sheet, :worksheet, :path
		def initialize(title, path, environment)
			@sheet = self.class.create_sheet(title, path)
			@worksheet = self.class.worksheet(sheet, environment)
		end

		def write_header(header)
			worksheet.list.keys = header.unshift('name')
			worksheet.save
		end

		def write_row(value_hash)
			worksheet.list.push(value_hash)
			worksheet.save
		end

		def self.first_or_create(title)
			spreadsheet = google.root_collection.files("title" => title, "title-exact" => true).first
			spreadsheet ? spreadsheet : google.create_spreadsheet(title)
		end

		#returns a spreadsheet object
		def self.create_sheet(title, path)
			folder = go_to_collection(path) if path
			if folder 
				spreadsheet = folder.files("title" => title, "title-exact" => true).first
				if spreadsheet 
					return spreadsheet
				else
					file = first_or_create(title)
					folder.add(file)
					google.root_collection.remove(file)
					return folder.files("title" => title, "title-exact" => true).first
				end
			else
				first_or_create(title)
			end
		end

		#returns a worksheet object
		def self.worksheet(spreadsheet, title)
			worksheet = spreadsheet.worksheet_by_title(title)
			worksheet ? delete_all_rows(worksheet) : spreadsheet.add_worksheet(title)
		end

		#returns a collection object
		def self.go_to_collection(directory)
			if directory
				path = directory.split('/')
				go_to_subcollection(google.collection_by_title(path.first),path[1..-1])
			end
		end

		#returns a collection object
		def self.go_to_subcollection(base, subs)
			puts "Folder doesn't exist in specified path" and exit if base.nil?
			if subs.empty?
				return base
			else
				base = base.subcollection_by_title(subs.first)
				go_to_subcollection(base,subs[1..-1])
			end
		end

		def self.delete_all_rows(worksheet)
			worksheet.list.each do |row|
				row.clear
			end
			worksheet.save
			worksheet
		end

	end
end