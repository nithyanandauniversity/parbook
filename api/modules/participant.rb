module Parbook

	class ParticipantsAPI < Grape::API
		namespace "participant" do
			post do
				participant = Participant.create(params[:participant])
				default_update = {}

				if params[:addresses]
					params[:addresses].each do |_address|

						address = Address.create({
							street: _address.street,
							city: _address.city,
							state: _address.state,
							postal_code: _address.postal_code,
							country: _address.country,
							participant_uuid: participant.uuid
						})
						default_update[:default_address] = address.id if _address[:default]
					end

					if !default_update[:default_address]
						default_update[:default_address] = participant.addresses.first.id
					end
				end

				if params[:contacts]
					params[:contacts].each do |_contact|

						contact = ContactNumber.create({
							contact_type: _contact.contact_type,
							value: _contact.value,
							participant_uuid: participant.uuid
						})
						default_update[:default_contact] = contact.id if _contact[:default]
					end

					if !default_update[:default_contact]
						default_update[:default_contact] = participant.contacts.first.id
					end
				end

				if default_update[:default_address] || default_update[:default_contact]
					participant.update(default_update)
				end

				participant
			end

			put "/:id" do
				participant = Participant.find(id: params[:id])
				participant.update(params[:participant])

				default_update = {}

				if params[:addresses]
					Sequel::Model.db.transaction do
						participant.addresses.delete

						params[:addresses].each do |_address|
							address = Address.create({
								street: _address.street,
								city: _address.city,
								state: _address.state,
								postal_code: _address.postal_code,
								country: _address.country,
								participant_uuid: participant.uuid
							})
							default_update[:default_address] = address.id if _address[:default]
						end

						if !default_update[:default_address]
							default_update[:default_address] = participant.addresses.first.id
						end
					end
				end

				if params[:contacts]
					Sequel::Model.db.transaction do
						participant.contacts.delete
						params[:contacts].each do |_contact|

							contact = ContactNumber.create({
								contact_type: _contact.contact_type,
								value: _contact.value,
								participant_uuid: participant.uuid
							})
							default_update[:default_contact] = contact.id if _contact[:default]
						end

						if !default_update[:default_contact]
							default_update[:default_contact] = participant.contacts.first.id
						end
					end
				end

				if default_update[:default_address] || default_update[:default_contact]
					participant.update(default_update)
				end

				participant
			end

			delete "/:id/address/:address_id" do
				participant = Participant.find(id: params[:id])
				_address = participant.addresses.where(id: params[:address_id]).first

				reset_default = participant[:default_address] == _address.id

				_address.destroy

				if reset_default
					default_address = participant.addresses.count > 0 ? participant.addresses.first.id : nil
					participant.update({default_address: default_address})
				end
			end

			delete "/:id/contact/:contact_id" do
				participant = Participant.find(id: params[:id])
				_contact = participant.contacts.where(id: params[:contact_id]).first

				reset_default = participant[:default_contact] == _contact.id

				_contact.destroy

				if reset_default
					default_contact = participant.contacts.count > 0 ? participant.contacts.first.id : nil
					participant.update({default_contact: default_contact})
				end
			end

			delete "/:id" do
				participant = Participant.find(id: params[:id])
				participant.addresses.destroy
				participant.contacts.destroy
				participant.destroy
			end

		end
	end

end

