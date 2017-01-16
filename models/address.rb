class Address < Sequel::Model
	self.plugin :timestamps

	def participant
		Participant.find(uuid: self.participant_uuid)
	end
end
