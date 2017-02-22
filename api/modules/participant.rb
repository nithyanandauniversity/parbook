module Parbook

	class ParticipantsAPI < Grape::API
		namespace "participant" do

			get do
				return Participant.search(params[:search])
			end

			get '/:id' do
				participant             = Participant.find({id: params[:id]})
				participant[:contacts]  = participant.contacts
				participant[:addresses] = participant.addresses
				participant[:comments]  = participant.comments

				participant
			end

			post do
				participant = Participant.create(params[:participant])
				uuid        = SecureRandom.uuid
				member_id   = participant.created_at.strftime('%Y%m%d') + '-' + SecureRandom.hex(4)
				participant.update({uuid: uuid, member_id: member_id})
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
						default_update[:default_address] = address.id if [true, 'true'].include?(_address[:default])
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
						default_update[:default_contact] = contact.id if [true, 'true'].include?(_contact[:default])
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

			post '/:id/comments' do
				participant = Participant.find(id: params[:id])

				comment = Comment.create({
					participant_uuid: participant.uuid,
					created_by: params[:created_by],
					content: params[:content],
					event_uuid: params[:event_uuid] || nil
				})

				comment
			end

			put "/:id" do
				participant = Participant.find(id: params[:id])
				participant.update(params.participant)

				default_update = {}

				if params.addresses
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
							default_update[:default_address] = address.id if [true, 'true'].include?(_address[:default])
						end

						if !default_update[:default_address]
							default_update[:default_address] = participant.addresses.first.id
						end
					end
				end

				if params.contacts
					Sequel::Model.db.transaction do
						participant.contacts.delete

						params[:contacts].each do |_contact|
							contact = ContactNumber.create({
								contact_type: _contact.contact_type,
								value: _contact.value,
								participant_uuid: participant.uuid
							})
							default_update[:default_contact] = contact.id if [true, 'true'].include?(_contact[:default])
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
				_address = participant.addresses.where({id: params[:address_id]}).first

				reset_default = participant[:default_address] == _address.id

				_address.destroy

				if reset_default
					default_address = participant.addresses.count > 0 ? participant.addresses.first.id : nil
					participant.update({default_address: default_address})
				end

				{id: params[:id]}
			end

			delete "/:id/contact/:contact_id" do
				participant = Participant.find(id: params[:id])
				_contact = participant.contacts.where({id: params[:contact_id]}).first

				reset_default = participant[:default_contact] == _contact.id

				_contact.destroy

				if reset_default
					default_contact = participant.contacts.count > 0 ? participant.contacts.first.id : nil
					participant.update({default_contact: default_contact})
				end

				{id: params[:id]}
			end

			delete "/:id/comments/:comment_id" do
				participant = Participant.find(id: params[:id])

				comment = participant.comments.where(id: params[:comment_id])
				comment.destroy
			end

			delete "/:id" do
				unless params[:id] == "delete_all"
					participant = Participant.find(id: params[:id])
					participant.addresses.destroy
					participant.contacts.destroy
					participant.destroy
				else
					count = 0
					Participant.each do |participant|
						participant.addresses.destroy
						participant.contacts.destroy
						count += 1 if participant.destroy
					end

					count
				end
			end

		end
	end

end

