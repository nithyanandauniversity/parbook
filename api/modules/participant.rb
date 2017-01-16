module Parbook

	class ParticipantsAPI < Grape::API
		namespace "participant" do
			post do
				participant = Participant.create(params[:participant])
				default_update = {}

				if params[:addresses]
					params[:addresses].each do |address|
						address.participant_uuid = participant.uuid
						Address.create(address)
						default_update[:default_address] = address.id if address.default
					end

					if !participant.default_address
						default_update[:default_address] = participant.addresses.first.id
					end
				end

				if params[:contacts]
					params[:contacts].each do |contact|
						contact.participant_uuid = participant.uuid
						ContactNumber.create(contact)
						default_update[:default_contact] = contact.id if contact.default
					end

					if !participant.default_contact
						default_update[:default_contact] = participant.contacts.first.id
					end
				end

				if default_update[:default_address] || default_update[:default_contact]
					participant.update(default_update)
				end

				participant
			end

			# post "/:id/address" do
			# 	center = Center.find(id: params[:id])
			# 	center.add_address(params[:address])
			# end

			# put "/:id" do
			# 	center = Center.find(id: params[:id])
			# 	center.update(params[:center])
			# end

			# put "/:id/address/:address_id" do
			# 	center = Center.find(id: params[:id])
			# 	address = center.addresses.find(id: params[:address_id]).first
			# 	address.update(params[:address])
			# end

			# delete "/:id" do
			# 	center = Center.find(id: params[:id])
			# 	center.destroy
			# end

			# delete "/:id/address/:address_id" do
			# 	center = Center.find(id: params[:id])
			# 	address = center.addresses.find(id: params[:address_id]).first
			# 	address.destroy
			# end

		end
	end

end

