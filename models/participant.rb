class Participant < Sequel::Model
	self.plugin :timestamps

	MKT_NONE      = 0
	MKT_VOLUNTEER = 1
	MKT_THANEDAR  = 2
	MKT_KOTARI    = 3
	MKT_MAHANT    = 4
	MKT_SRIMAHANT = 5

	def addresses
		Address.where(participant_uuid: uuid)
	end

	def address
		if default_address
			res = addresses.where(id: default_address)
		else
			res = []
		end

		res.first
	end

	def contacts
		ContactNumber.where(participant_uuid: uuid)
	end

	def contact
		if default_contact
			res = contacts.where(id: default_contact)
		else
			res = []
		end

		res.first
	end


	def self.search(params)
		size       = params && params[:limit].to_i || 10
		page       = params && params[:page].to_i || 1
		keyword    = params && params[:keyword] || nil
		attributes = params && params[:attributes] || nil

		if keyword || attributes
			# SEARCH
			if keyword
				if attributes
					Participant.where(
						(Sequel.like(:first_name, "%#{keyword}%")) |
						(Sequel.like(:last_name, "%#{keyword}%")) |
						(Sequel.like(:email, "%#{keyword}%")) &
						(Sequel.like(:participant_attributes, "%#{attributes.join('%')}%"))
					).paginate(page, size)
				else
					Participant.where(
						(Sequel.like(:first_name, "%#{keyword}%")) |
						(Sequel.like(:last_name, "%#{keyword}%")) |
						(Sequel.like(:email, "%#{keyword}%"))
					).paginate(page, size)
				end
			else
				Participant.where(
					(Sequel.like(:participant_attributes, "%#{attributes.join('%')}%"))
				).paginate(page, size)
			end
		else
			# ALL
			Participant.dataset.paginate(page, size)
		end
	end

end
