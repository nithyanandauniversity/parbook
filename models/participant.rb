class Participant < Sequel::Model
	self.plugin :timestamps

	def addresses
		Address.where(participant_uuid: uuid)
	end

	def contacts
		ContactNumber.where(participant_uuid: uuid)
	end
end
