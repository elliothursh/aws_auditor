require 'google_drive'

module AwsAuditor
	class GoogleSheet
		extend GoogleWrapper

		attr_accessor :sheet, :worksheet
		def initialize(title, environment)
			@sheet = self.class.first_or_create(title)
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

		#returns a spreadsheet object
		def self.first_or_create(title)
			spreadsheet = google.file_by_title(title)
			spreadsheet ? spreadsheet : google.create_spreadsheet(title)
		end

		#returns a worksheet object
		def self.worksheet(spreadsheet, title)
			worksheet = spreadsheet.worksheet_by_title(title)
			worksheet ? worksheet : spreadsheet.add_worksheet(title)
		end

	end
end