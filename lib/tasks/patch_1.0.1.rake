namespace :patch do

	desc "Patch Full Names"
	task :full_name => [:environment] do

		Participant.all.each do |participant|
			full_name = [(participant.first_name || '').strip(), (participant.last_name || '').strip()].join(' ')
			puts participant.update({full_name: full_name})
		end
	end
end
