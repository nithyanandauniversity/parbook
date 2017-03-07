class Participant < Sequel::Model
	self.plugin :timestamps

	MKT_NONE      = 0
	MKT_VOLUNTEER = 1
	MKT_THANEDAR  = 2
	MKT_KOTARI    = 3
	MKT_MAHANT    = 4
	MKT_SRIMAHANT = 5

	# Participant Attribute Order
	# role
	# ia_graduate
	# ia_dates
	# is_healer

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

	def comments
		Comment.where(participant_uuid: uuid)
	end


	def self.search(params)
		# puts params.inspect
		size        = params && params[:limit].to_i || 10
		page        = params && params[:page].to_i || 1
		keyword     = params && params[:keyword] || nil
		attributes  = params && params[:attributes] || nil
		center_code = params && params[:center_code] || nil

		# puts "PAGE: #{page} || SIZE: #{size}\n\n"

		if center_code
			participants = Participant.where(center_code: center_code)
		else
			participants = Participant.order(:id)
		end

		if keyword || attributes
			# SEARCH
			if keyword
				if attributes
					participants = participants.where(
						(Sequel.like(:first_name, "%#{keyword}%")) |
						(Sequel.like(:last_name, "%#{keyword}%")) |
						(Sequel.like(:other_names, "%#{keyword}%")) |
						(Sequel.like(:email, "%#{keyword}%")) &
						(Sequel.like(:participant_attributes, "%#{attributes.join('%')}%"))
					).paginate(page, size)
				else
					participants = participants.where(
						(Sequel.like(:first_name, "%#{keyword}%")) |
						(Sequel.like(:last_name, "%#{keyword}%")) |
						(Sequel.like(:other_names, "%#{keyword}%")) |
						(Sequel.like(:email, "%#{keyword}%"))
					).paginate(page, size)
					# participants = Participant.where("first_name COLLATE UTF8_GENERAL_CI LIKE ? " +
					# 	"OR last_name COLLATE UTF8_GENERAL_CI LIKE ? " +
					# 	"OR other_names COLLATE UTF8_GENERAL_CI LIKE ? " +
					# 	"OR email COLLATE UTF8_GENERAL_CI LIKE ?",
					# 	"'%#{keyword}%'", "'%#{keyword}%'",
					# 	"'%#{keyword}%'", "'%#{keyword}%'"
					# 	).paginate(page, size)
				end
			else
				participants = participants.where(
					(Sequel.like(:participant_attributes, "%#{attributes.join('%')}%"))
				).paginate(page, size)
			end
		else
			# ALL
			participants = participants.paginate(page, size)
		end

		[{
			participants: JSON.parse(participants.to_json(:include => :contact)),
			page_count: participants.page_count,
			page_size: participants.page_size,
			page_range: participants.page_range,
			current_page: participants.current_page,
			pagination_record_count: participants.pagination_record_count,
			current_page_record_count: participants.current_page_record_count,
			current_page_record_range: participants.current_page_record_range,
			first_page: participants.first_page?,
			last_page: participants.last_page?
		}]
	end

end
