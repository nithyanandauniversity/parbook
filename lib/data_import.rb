require 'csv'

module DataImport
	COUNTRIES_YML = HashWithIndifferentAccess.new(YAML.load(File.read(File.expand_path('../countries.yml', __FILE__))))
	DIALCODES_YML = HashWithIndifferentAccess.new(YAML.load(File.read(File.expand_path('../dial_codes.yml', __FILE__))))

	module Participants

		def self.generate_countries_list
			countries = []
			COUNTRIES_YML.each do |code, country|
				countries << {
					code: code,
					name: "#{country} (#{code})",
					country: country
				}
			end
			countries
		end

		def self.generate_dial_codes_list
			return DIALCODES_YML['codes'].collect { |d| "(#{d['dial_code']})" }
		end

		def self.import(creator, file, centers)
			puts "Module DataImport::Participant.import works !"
			error_records  = []
			countries_list = Participants.generate_countries_list()
			dial_codes     = Participants.generate_dial_codes_list()

			data = File.read("#{file.path}")

			gender_list = {
				'M' => "Male",
				'F' => "Female"
			}

			contact_type_list = {
				"M" => "Mobile",
				"H" => "Home"
			}

			smkt_list = {
				"S" => Participant::SMKT_SRIMAHANT,
				"M" => Participant::SMKT_MAHANT,
				"K" => Participant::SMKT_KOTARI,
				"T" => Participant::SMKT_THANEDAR,
				"V" => Participant::SMKT_VOLUNTEER,
				"N" => Participant::SMKT_NONE
			}

			begin

				Participant.all.each { |p| p.destroy }
				ContactNumber.all.each { |c| c.destroy }
				Address.all.each { |a| a.destroy }

				rcount = 0
				count  = 0
				header = ''

				data.split('\n').each do |_row|

					CSV.parse(_row) do |row|

						header = row if rcount == 0

						if rcount > 0
							participant = {
								:number      => row[0],
								:first_name  => row[1],
								:last_name   => row[2],
								:gender      => gender_list[row[3].to_s],
								:email       => row[4],
								:other_names => row[5]
							}

							participant[:contact_numbers] = [
								{
									:value        => row[6],
									:contact_type => contact_type_list[row[7].to_s]
								},
								{
									:value        => row[8],
									:contact_type => contact_type_list[row[9].to_s]
								}
							]

							participant[:participant_attributes] = {
								role: smkt_list[row[13].to_s],
								ia_graduate: row[10] == "Y",
								ia_dates: row[11].to_s,
								is_healer: row[12] == "Y"
							}.to_json

							participant[:address] = {
								:street      => row[14],
								:city        => row[15],
								:state       => row[16],
								:postal_code => row[17],
								:country     => row[18]
							}

							participant[:created_by]  = creator
							participant[:notes]       = row[19]
							participant[:center_code] = row[20].to_s.split(' - ')[1]

							data = {:participant => participant}

							# VALIDATION LIST
							# 1: Empty first name
							data = Participants.validate_empty_name(data)
							# 2: Empty Email and Contact
							data = Participants.validate_email_contact(data)
							# 3: Invalid Email Address
							data = Participants.validate_email(data)
							# 4: Empty City / Country
							data = Participants.validate_city_country(data, countries_list)
							# 5: Invalid contact number
							data = Participants.validate_contact(data, dial_codes)
							# 6: Empty Center Info / Invalid Center
							data = Participants.validate_center(data, JSON.parse(centers))
							# 7: Check Duplicate with first_name / last_name / Email / Contact
							data = Participants.validate_duplicates(data)

							if data[:error] == true
								error_records << {row: row, data: data}
							else
								count += 1 if Participants.save_record(data)
							end
						end
						rcount += 1
					end
				end

				puts "\n\n#{count} Records Saved / #{rcount} Total Rows"

				# if error_records.length > 0
				# return {count: count, file: Participants.generate_error_report(error_records, header)}
				return Participants.generate_error_report(error_records, header)
				# else
					# return {count: count, file: nil}
				# end

			rescue Exception => e
				puts e.inspect
			end
		end

		def self.import_singapore(creator, file, centers)
			puts "Module DataImport::Participant.import works !"
			error_records  = []
			countries_list = Participants.generate_countries_list()
			dial_codes     = Participants.generate_dial_codes_list()

			data = File.read("#{file.path}")

			gender_list = {
				'M' => "Male",
				'F' => "Female"
			}

			contact_type_list = {
				"M" => "Mobile",
				"H" => "Home"
			}

			smkt_list = {
				"S" => Participant::SMKT_SRIMAHANT,
				"M" => Participant::SMKT_MAHANT,
				"K" => Participant::SMKT_KOTARI,
				"T" => Participant::SMKT_THANEDAR,
				"V" => Participant::SMKT_VOLUNTEER,
				"N" => Participant::SMKT_NONE
			}

			begin
				Participant.all.each { |p| p.destroy }
				ContactNumber.all.each { |c| c.destroy }
				Address.all.each { |a| a.destroy }

				rcount = 0
				count  = 0
				header = ''

				data.split('\n').each do |_row|
					CSV.parse(_row) do |row|
						header = row if rcount == 0

						if rcount > 0
							participant = {
								:number         => row[0],
								:first_name     => row[1],
								:last_name      => row[2],
								:gender         => gender_list[row[3].to_s],
								:email          => row[4],
								:other_names    => row[5],
								:member_id      => row[6].gsub('SG-','').strip,
								:default_friend => row[23] ? row[23].gsub('SG-','').strip : nil
							}

							participant[:contact_numbers] = [
								{
									:value        => row[7],
									:contact_type => contact_type_list[row[8].to_s]
								},
								{
									:value        => row[9],
									:contact_type => contact_type_list[row[10].to_s]
								}
							]

							participant[:participant_attributes] = {
								role: smkt_list[row[14].to_s],
								ia_graduate: row[11] == "Y",
								ia_dates: row[12].to_s,
								is_healer: row[13] == "Y"
							}.to_json

							participant[:address] = {
								:street      => row[15],
								:city        => row[16],
								:state       => row[17],
								:postal_code => row[18],
								:country     => row[19]
							}

							participant[:created_by]  = creator
							participant[:notes]       = row[20]
							participant[:center_code] = row[21].to_s.split(' - ')[1]

							participant[:enrichers] = JSON.parse(row[22])
							# participant[:default_friend] = row[23]
							participant[:commecnts] = JSON.parse(row[24])

							data = {:participant => participant}

							# VALIDATION LIST
							# 1: Empty first name
							data = Participants.validate_empty_name(data)
							# 2: Empty Email and Contact
							data = Participants.validate_email_contact(data)
							# 3: Invalid Email Address
							data = Participants.validate_email(data)
							# 4: Empty City / Country
							data = Participants.validate_city_country(data, countries_list)
							# 5: Invalid contact number
							data = Participants.validate_contact(data, dial_codes)
							# 6: Empty Center Info / Invalid Center
							data = Participants.validate_center(data, JSON.parse(centers))
							# 7: Check Duplicate with first_name / last_name / Email / Contact
							data = Participants.validate_duplicates(data)

							if data[:error] == true
								row.pop()
								row.pop()
								error_records << {row: row, data: data}
							else
								count += 1 if Participants.save_record_sg(data)
							end
						end
						rcount += 1
					end
				end

				puts "\n\n#{count} Records Saved / #{rcount} Total Rows"
				return Participants.generate_error_report(error_records, header)

			rescue Exception => e
				puts e.inspect
			end
		end

		def self.validate_empty_name(record)
			data = record[:participant]

			record[:empty_name] = !data[:first_name] || data[:first_name].to_s.length == 0
			record[:error] = true if record[:empty_name]
			record
		end

		def self.validate_email_contact(record)
			data          = record[:participant]
			empty_email   = !data[:email] || data[:email].to_s.length == 0
			empty_contact = !data[:contact_numbers][0][:value] || data[:contact_numbers][0][:value].to_s.length == 0

			record[:empty_email_contact] = empty_email && empty_contact
			record[:error] = true if record[:empty_email_contact]
			record
		end

		def self.validate_email(record)
			data = record[:participant]
			# emailRegex = /[a-z0-9](\.?[a-z0-9_-]){0,}@[a-z0-9-]+\.([a-z]{1,6}\.)?[a-z]{2,6}$/i
			emailRegex = /[a-z0-9](\.?[a-z0-9_-]){0,}@[a-z0-9-\.]+/i

			record[:invalid_email] = data[:email] && data[:email].to_s.length > 0 && (data[:email] =~ emailRegex).nil?
			record[:error] = true if record[:invalid_email]
			record
		end

		def self.validate_city_country(record, countries_list)
			data          = record[:participant]
			empty_city    = !data[:address][:city] || data[:address][:city].to_s.length == 0
			empty_country = !data[:address][:country] || data[:address][:country].to_s.length == 0

			if !empty_country
				_country = countries_list.select { |c| c[:country] == data[:address][:country] }

				if _country && _country.length > 0
					data[:address][:country] = _country[0][:country]
				else
					record[:invalid_country]   = true
				end
			end

			record[:empty_city_country] = empty_city && empty_country
			record[:error] = true if record[:empty_city_country] || record[:invalid_country]
			record
		end

		def self.validate_contact(record, dial_codes)
			data       = record[:participant]
			phoneRegex = /\(\+(?:[\d]{1,4})\)(?:[\s]{0,1})(?:[\s-]{1}|[\d])+\d/
			codeRegex  = /\(\+(?:[\d]{1,4})\)/

			primary_contact   = data[:contact_numbers][0][:value]
			secondary_contact = data[:contact_numbers][1][:value]

			record[:empty_primary_phone] = !primary_contact || primary_contact.to_s.length == 0
			record[:empty_secondary_phone] = !secondary_contact || secondary_contact.to_s.length == 0

			record[:invalid_primary_phone]   = !record[:empty_primary_phone] && (primary_contact =~ phoneRegex).nil?
			record[:invalid_secondary_phone] = !record[:empty_secondary_phone] && (secondary_contact =~ phoneRegex).nil?

			if !record[:invalid_primary_phone] && !record[:empty_primary_phone]
				record[:invalid_primary_code] = !dial_codes.include?(primary_contact.scan(codeRegex)[0])
			end

			if !record[:invalid_secondary_phone] && !record[:empty_secondary_phone]
				record[:invalid_secondary_code] = !dial_codes.include?(primary_contact.scan(codeRegex)[0])
			end

			if (!record[:empty_primary_phone] && record[:invalid_primary_phone]) ||
				record[:invalid_primary_code] ||
				record[:invalid_secondary_phone] ||
				record[:invalid_secondary_code]
				record[:error] = true
			end

			record
		end

		def self.validate_center(record, centers)
			data = record[:participant]
			ex   = centers.find { |c| c['code'] == data[:center_code] }

			record[:invalid_center] = ex && ex.length == 0
			record[:error] = true if record[:invalid_center]
			record
		end

		def self.validate_duplicates(record)
			data = record[:participant]
			con_participants = ContactNumber.where(
				value: data[:contact_numbers][0][:value]
			).map { |c|
				c.participant_uuid if c.participant
			}.compact

			ex_participant = Participant
				.where(first_name: data[:first_name], last_name: data[:last_name], email: data[:email])
				.where("uuid IN ?", con_participants).all

			record[:duplicate_record] = ex_participant && ex_participant.length > 0
			record[:error] = true if record[:duplicate_record]
			record
		end


		def self.save_record(data)
			puts "SAVING #{data.inspect}\n\n"
			participant = Participant.create(
				first_name: data[:participant][:first_name],
				last_name: data[:participant][:last_name],
				email: data[:participant][:email],
				gender: data[:participant][:gender],
				other_names: data[:participant][:other_names],
				uuid: SecureRandom.uuid,
				center_code: data[:participant][:center_code],
				notes: data[:participant][:notes],
				created_by: data[:participant][:created_by],
				participant_attributes: data[:participant][:participant_attributes]
			)

			member_id = participant.created_at.strftime('%Y%m%d') + '-' + SecureRandom.hex(4)
			default_contact = nil
			default_address = nil

			if !data[:empty_city_country]
				address = Address.create(
					street: data[:participant][:address][:street],
					city: data[:participant][:address][:city],
					state: data[:participant][:address][:state],
					postal_code: data[:participant][:address][:postal_code],
					country: data[:participant][:address][:country],
					participant_uuid: participant.uuid
				)
				default_address = address.id
			end

			if !data[:empty_primary_phone] && !data[:invalid_primary_phone]
				primary_contact = ContactNumber.create(
					contact_type: data[:participant][:contact_numbers][0][:contact_type],
					value: data[:participant][:contact_numbers][0][:value],
					participant_uuid: participant.uuid
				)
				default_contact = primary_contact.id
			end

			if !data[:empty_secondary_phone] && !data[:invalid_secondary_phone]
				ContactNumber.create(
					contact_type: data[:participant][:contact_numbers][1][:contact_type],
					value: data[:participant][:contact_numbers][1][:value],
					participant_uuid: participant.uuid
				)
			end

			participant.update(member_id: member_id, default_address: default_address, default_contact: default_contact)

			return true
		end

		def self.save_record_sg(data)
			# puts "SAVING SG #{data.inspect}\n\n"
			participant = Participant.create(
				first_name: data[:participant][:first_name],
				last_name: data[:participant][:last_name],
				email: data[:participant][:email],
				gender: data[:participant][:gender],
				other_names: data[:participant][:other_names],
				uuid: SecureRandom.uuid,
				member_id: data[:participant][:member_id],
				center_code: data[:participant][:center_code],
				notes: data[:participant][:notes],
				created_by: data[:participant][:created_by],
				default_friend: data[:participant][:default_friend],
				participant_attributes: data[:participant][:participant_attributes]
			)

			default_contact = nil
			default_address = nil

			if !data[:empty_city_country]
				address = Address.create(
					street: data[:participant][:address][:street],
					city: data[:participant][:address][:city],
					state: data[:participant][:address][:state],
					postal_code: data[:participant][:address][:postal_code],
					country: data[:participant][:address][:country],
					participant_uuid: participant.uuid
				)
				default_address = address.id
			end

			if !data[:empty_primary_phone] && !data[:invalid_primary_phone]
				primary_contact = ContactNumber.create(
					contact_type: data[:participant][:contact_numbers][0][:contact_type],
					value: data[:participant][:contact_numbers][0][:value],
					participant_uuid: participant.uuid
				)
				default_contact = primary_contact.id
			end

			if !data[:empty_secondary_phone] && !data[:invalid_secondary_phone]
				ContactNumber.create(
					contact_type: data[:participant][:contact_numbers][1][:contact_type],
					value: data[:participant][:contact_numbers][1][:value],
					participant_uuid: participant.uuid
				)
			end

			participant.update(default_address: default_address, default_contact: default_contact)

			data[:participant][:enrichers].each do |enricher|
				ParticipantFriend.create(participant_id: participant.member_id, friend_id: enricher.gsub('SG-','').strip)
			end

			data[:participant][:commecnts].each do |comment|
				Comment.create({
					participant_uuid: participant.uuid,
					created_by: comment['added_by'],
					content: comment['content'],
					event_uuid: comment['event_uuid'] || nil,
					created_at: comment['timestamp']
				})
			end
		end

		def self.generate_error_report(errors, header)
			CSV.generate do |csv|
				header << "ERRORS !"
				csv << header

				errors.each do |error|
					row = error[:row]

					message = []
					message << "Name Cannot be Empty" if error[:data][:empty_name]
					message << "Email and Contact both cannot be blank" if error[:data][:empty_email_contact]
					message << "Invalid Email Address" if error[:data][:invalid_email]
					message << "City and Country cannot be empty" if error[:data][:empty_city_country]
					message << "Invalid Country name" if error[:data][:invalid_country]
					message << "Invalid Primary Phone number" if error[:data][:invalid_primary_phone]
					message << "Wrong Country code for primary contact" if error[:data][:invalid_primary_code]
					message << "Invalid Secondary Phone number" if error[:data][:invalid_secondary_phone]
					message << "Wrong Country code for secondary contact" if error[:data][:invalid_secondary_code]
					message << "Invalid Center information" if error[:data][:invalid_center]
					message << "DUPLICATE RECORD! The same record already exist in the database" if error[:data][:duplicate_record]

					row << message.join(' | ')
					csv << row
				end
			end
		end
	end

end
