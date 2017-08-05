class Participant < Sequel::Model
	self.plugin :timestamps

	SMKT_NONE      = 0
	SMKT_VOLUNTEER = 1
	SMKT_THANEDAR  = 2
	SMKT_KOTARI    = 3
	SMKT_MAHANT    = 4
	SMKT_SRIMAHANT = 5

	# Participant Attribute Order
	# role
	# ia_graduate
	# ia_dates
	# is_healer

	def self.participant_attr
		[:first_name, :last_name, :other_names, :email, :gender, :dob, :member_id, :uuid, :default_contact, :default_address, :center_code, :notes, :participant_attributes, :created_at, :updated_at]
	end

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

	def friends
		ParticipantFriend.where(participant_id: member_id).collect { |friend|
			Participant.find(member_id: friend.friend_id)
		}.compact
	end

	def enricher_names
		friends.map { |f| "#{f.first_name} #{f.last_name}" }
	end


	def self.search(params)

		size        = params && params[:limit].to_i || 10
		page        = params && params[:page].to_i || 1
		keyword     = params && params[:keyword] || nil
		attributes  = params && params[:attributes] || nil
		center_code = params && params[:center_code] || nil
		ext_search  = params && params[:ext_search] || nil

		# puts "KEYWORD #{keyword} || ATTRIBUTES #{attributes}\n"
		# puts "PAGE: #{page} || SIZE: #{size}\n\n"
		# puts "EXT_SEARCH :: #{ext_search.inspect}"

		if ext_search && !ext_search.blank?
			if params[:center_codes]
				participants = Participant.where("center_code IN ?", params[:center_codes])
			elsif ext_search[:global]
				participants = Participant.order('participants.id')
			end
		else
			if center_code
				participants = Participant.where(center_code: center_code)
			else
				participants = Participant.order('participants.id')
			end
		end


		if (keyword && !keyword.blank?) || (attributes && !attributes.blank?)
			# SEARCH
			if !keyword.blank?

				contact_uuids = ContactNumber.where(
					(Sequel.like(:value, "%#{keyword}%"))
				).map { |contact|
					contact.participant_uuid if contact.participant
				}.compact

				if attributes && !attributes.blank?

					participants = participants.where(
						(Sequel.ilike(:first_name, "%#{keyword}%")) |
						(Sequel.ilike(:last_name, "%#{keyword}%")) |
						(Sequel.ilike(:other_names, "%#{keyword}%")) |
						(Sequel.ilike(:email, "%#{keyword}%")) |
						(Sequel.ilike(:participant_attributes, "%#{attributes.join('%')}%"))
					)
					.or("uuid IN ?", contact_uuids)
					.paginate(page, size)

				else

					participants = participants.where(
						(Sequel.ilike(:first_name, "%#{keyword}%")) |
						(Sequel.ilike(:last_name, "%#{keyword}%")) |
						(Sequel.ilike(:other_names, "%#{keyword}%")) |
						(Sequel.ilike(:email, "%#{keyword}%"))
					)
					.or("uuid IN ?", contact_uuids)
					.paginate(page, size)

				end
			else

				participants = participants.where(
					(Sequel.ilike(:participant_attributes, "%#{attributes.join('%')}%"))
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


	def self.download(params)
		center_code       = params[:center_code] || nil
		include_address   = [true, 'true'].include?(params[:with_address]) || false
		include_contacts  = [true, 'true'].include?(params[:with_contacts]) || false
		include_enrichers = [true, 'true'].include?(params[:enrichers]) || false

		if center_code
			participants = Participant.where(center_code: center_code)
		else
			participants = Participant.order('participants.id')
		end

		includes = []

		if include_contacts
			includes << :contacts
		else
			includes << :contact
		end

		includes << :enricher_names if include_enrichers

		includes << :address if include_address

		return JSON.parse(participants.to_json(:include => includes))
	end

end


