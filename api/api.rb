Dir["#{File.dirname(__FILE__)}/modules/**/*.rb"].each { |f| require f; puts f }

module Parbook
	class API < Grape::API
		version 'v1', using: :path
		format :json
		get do
			"Hello api"
		end

		mount Parbook::ParticipantsAPI
	end
end
