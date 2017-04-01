require 'csv'

namespace :migrations do

	desc "Import Participants Information`"
	task :import_participant, [:file] => [:environment] do |t, args|

		file    = args[:file]
		puts file
		data    = File.read("#{file}")

		begin
			data.split('\n').each do |row|
				# row = row.gsub(/(?<!^|,)"(?!,|$)/,"'")

				rcount = 0
				count = 0

				CSV.parse(row) do |r|
					# puts r.inspect
					rcount += 1

					smkts = ["None", "Volunteer", "Thanedar", "Kotari", "Mahant", "Sri Mahant"]

					first_name  = r[0]
					last_name   = r[1]
					gender      = r[2]
					email       = r[3]
					member_id   = r[4]
					other_names = r[5]
					notes       = r[13]

					if rcount > 1
						contacts    = JSON.parse(r[7])
						addresses   = JSON.parse(r[8])
						comments    = JSON.parse(r[15])

						attributes = {
							role: smkts.find_index(r[12]),
							ia_graduate: r[9].to_s.eql?('true'),
							ia_dates: r[10],
							is_healer: r[11].to_s.eql?('true')
						}

						data = {
							first_name: first_name,
							last_name: last_name,
							email: email,
							gender: gender,
							other_names: other_names,
							member_id: member_id.gsub('SG-',''),
							uuid: SecureRandom.uuid,
							notes: notes,
							participant_attributes: attributes.to_json,
							center_code: "5e54e63bf341"
						}

						Sequel::Model.db.transaction do
							participant = Participant.create(data)

							default_update = {}

							if addresses.length
								addresses.each do |_address|
									address = Address.create({
										street: _address['street'],
										city: _address['city'],
										state: _address['state'],
										postal_code: _address['postal_code'],
										country: _address['country'],
										participant_uuid: participant.uuid
									})

									default_update[:default_address] = address.id if _address['default'].to_s.eql?('true')
								end

								if !default_update[:default_address] && participant.addresses.count > 0
									default_update[:default_address] = participant.addresses.first.id
								end
							end

							if contacts.length
								contacts.each do |_contact|
									contact = ContactNumber.create({
										contact_type: _contact['type'],
										value: _contact['number'],
										participant_uuid: participant.uuid
									})

									default_update[:default_contact] = contact.id if _contact[:default].to_s.eql?('true')
								end

								if !default_update[:default_contact] && participant.contacts.count > 0
									default_update[:default_contact] = participant.contacts.first.id
								end
							end

							if default_update[:default_address] || default_update[:default_contact]
								participant.update(default_update)
							end

							if comments.length
								comments.each do |comment|
									Comment.create({
										participant_uuid: participant.uuid,
										created_by: comment['added_by'],
										content: comment['content'],
										event_uuid: comment['event_uuid'] || nil,
										created_at: comment['timestamp']
									})
								end
							end

							puts participant.inspect
						end
					end

					# return if rcount == 10
					rcount += 1
				end
			end
		rescue Exception => e
			puts e.inspect
		end
	end


	desc "Import Participant test task"
	task :import_file, [:creator, :file] => [:environment] do |t, args|
		creator = args[:creator]
		file    = args[:file]
		DataImport::Participant.import(creator, file)
	end

end
