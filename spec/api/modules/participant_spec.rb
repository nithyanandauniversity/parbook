require 'spec_helper'

describe "Participant" do

   it "should be able to Create Participant" do

      post '/api/v1/participant', participant: {
         first_name:"Saravana",
         email: "sgsaravana@gmail.com",
         uuid: SecureRandom.uuid
      }

      resp = JSON.parse(last_response.body)

      expect(resp["first_name"]).to eql("Saravana")
   end

   it "should be able to create participants with friends" do

      user1 = Participant.create(first_name: "Saravana", last_name: "Balaraj", member_id: "123123", email: "sgsaravana@gmail.com", gender: "Male", center_code: "1017", uuid: SecureRandom.uuid)
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", member_id: "112233", email: "psenthu@gmail.com", gender: "Male", center_code: "1017", uuid: SecureRandom.uuid)
      user3 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", member_id: "234123", email: "psenthu@gmail.com", gender: "Male", center_code: "1018", uuid: SecureRandom.uuid)

      expect(user1.uuid).not_to eql nil
      expect(user2.uuid).not_to eql nil
      expect(user3.uuid).not_to eql nil

      post '/api/v1/participant',
         participant: {first_name: "Sri Nithya Shreshtha", last_name: "Ananda", email: "sri.nithya.shreshthananda@gmail.com"},
         friends: [user1.member_id, user2.member_id, user3.member_id]

      response = JSON.parse(last_response.body)

      participant = Participant.find(id: response['id'])

      expect(ParticipantFriend.where(participant_id: participant.member_id).count).to eql 3
      expect(participant.friends.length).to eql 3
   end

   it "should have created full name attribute with first and last names" do
      post '/api/v1/participant', participant: {
         first_name:"Saravana",
         last_name:"B",
         email: "sgsaravana@gmail.com",
         uuid: SecureRandom.uuid
      }

      resp = JSON.parse(last_response.body)

      expect(resp["first_name"]).to eql("Saravana")
      expect(resp["last_name"]).to eql("B")
      expect(resp["full_name"]).to eql("Saravana B")
   end

   it "should be able to add address and contacts" do

      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [{street: "some road", city: "City", country: "SG", default: true}],
         contacts: [{contact_type: "Mobile", value: "454625363", default: true}]

      resp = JSON.parse(last_response.body)
      participant = Participant.find(id: resp["id"])

      expect(participant.addresses.count).to eql 1
      expect(participant.contacts.count).to eql 1
      expect(participant.default_address).to eql participant.addresses.first.id
      expect(participant.default_contact).to eql participant.contacts.first.id

   end

   it "should be able to assign default address and contact" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      participant = Participant.find(id: resp["id"])

      expect(participant.address.street).to eql("some road")
      expect(participant.contact.contact_type).to eql("Mobile")
      expect(participant.contact.value).to eql("454625363")
   end

   it "should be able to search participant by name or email" do
      Participant.all.each { |p| p.destroy }

      user1 = Participant.create(first_name: "Saravana", last_name: "Balaraj", email: "sgsaravana@gmail.com", gender: "Male", center_code: "1017")
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", email: "psenthu@gmail.com", gender: "Male", center_code: "1017")
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", email: "psenthu@gmail.com", gender: "Male", center_code: "1018")

      get "/api/v1/participant", search: {
         page: 1,
         limit: 10,
         keyword: 'Senthuran',
         center_code: "1017"
      }

      response = JSON.parse(last_response.body)[0]['participants']

      expect(response.length).to eql 1
      expect(response[0]['email']).to eql "psenthu@gmail.com"
      expect(response[0]['first_name']).to eql "Senthuran"
   end

   it "should be able to search participant by full name" do
      Participant.all.each { |p| p.destroy }

      post '/api/v1/participant', participant: {
         first_name: "Saravana", last_name: "Balaraj", email: "sgsaravana@gmail.com", gender: "Male", center_code: "1017"
      }

      post '/api/v1/participant', participant: {
         first_name: "Senthuran", last_name: "Ponnampalam", email: "psenthu@gmail.com", gender: "Male", center_code: "1017"
      }

      post '/api/v1/participant', participant: {
         first_name: "Senthuran", last_name: "Ponnampalam", email: "psenthu@gmail.com", gender: "Male", center_code: "1018"
      }


      get "/api/v1/participant", search: {
         page: 1,
         limit: 10,
         keyword: 'Senthuran Ponn',
         center_code: "1017"
      }

      response = JSON.parse(last_response.body)[0]['participants']

      expect(response.length).to eql 1
      expect(response[0]['email']).to eql "psenthu@gmail.com"
   end

   it "should be able to search by name or email case - insensitively" do
      Participant.all.each { |p| p.destroy }

      user1 = Participant.create(first_name: "Saravana", last_name: "Balaraj", email: "sgsaravana@gmail.com", gender: "Male", center_code: "1017")
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", email: "psenthu@gmail.com", gender: "Male", center_code: "1017")
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", email: "psenthu@gmail.com", gender: "Male", center_code: "1018")

      get "/api/v1/participant", search: {
         page: 1,
         limit: 10,
         keyword: 'senthuran',
         center_code: "1017"
      }

      response = JSON.parse(last_response.body)[0]['participants']

      expect(response.length).to eql 1
      expect(response[0]['email']).to eql "psenthu@gmail.com"
      expect(response[0]['first_name']).to eql "Senthuran"
   end

   it "should be able to search participants by participant_attributes" do
      Participant.all.each { |p| p.destroy }

      user1 = Participant.create({
         first_name: "Saravana",
         last_name: "Balaraj",
         email: "sgsaravana@gmail.com",
         gender: "Male",
         participant_attributes: {
            ia_graduate: true,
            healer: true
         }.to_s
      })
      user2 = Participant.create({
         first_name: "Senthuran",
         last_name: "Ponnampalam",
         email: "psenthu@gmail.com",
         gender: "Male",
         participant_attributes: {
            ia_graduate: false,
            healer: false
         }.to_s
      })

      get "/api/v1/participant", search: {
         page: 1,
         limit: 10,
         attributes: [":ia_graduate=>true", ":healer=>true"]
      }

      response = JSON.parse(last_response.body)[0]['participants']

      expect(response.length).to eql 1
      expect(response[0]['email']).to eql "sgsaravana@gmail.com"
      expect(response[0]['first_name']).to eql "Saravana"

      # puts response[0]['participant_attributes'].to_json
      # puts response[0]['participant_attributes']
      attributes = eval(response[0]['participant_attributes'])
      # puts attributes[:ia_graduate]
      expect(attributes[:ia_graduate]).to eql true
      expect(attributes[:healer]).to eql true
   end

   it "should be able to search participant by contact number or city or country" do
      Participant.all.each { |p| p.destroy }

      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      post '/api/v1/participant',
         participant: {first_name:"Senthuran", email: "psenthu@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "Singapore", country: "SG"},
            {street: "another one", city: "Colombo", country: "Sri Lanka"}
         ],
         contacts: [
            {contact_type: "Home", value: "77788866"},
            {contact_type: "Mobile", value: "2234445", is_default: true}
         ]

      expect(Participant.count).to eql 2

      get "/api/v1/participant", search: {
         page: 1,
         limit: 10,
         keyword: '33424'
      }

      response = JSON.parse(last_response.body)[0]['participants']

      expect(response.length).to eql 1
      expect(response[0]['first_name']).to eql "Saravana"
   end

   it "should be able to edit participant" do

      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.first_name).to eql("Saravana")

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      put "/api/v1/participant/#{_participant.member_id}",
         participant: {first_name: "Saravana1"}

      response = JSON.parse(last_response.body)
      participant = Participant.find(id: response["id"])

      expect(participant.first_name).to eql("Saravana1")
   end

   it "Should be able to edit address and contact" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      put "/api/v1/participant/#{_participant.member_id}",
         participant: {first_name: "Saravana"},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG", is_default: true}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453", is_default: true},
            {contact_type: "Mobile", value: "454625363"}
         ]

      response = JSON.parse(last_response.body)
      participant = Participant.find(id: response["id"])

      expect(participant.addresses.count).to eql 2
      expect(participant.contacts.count).to eql 2

      expect(participant.address.street).to eql "another one"
      expect(participant.contact.contact_type).to eql "Home"
   end

   it "should be able to delete address or contact" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.addresses.count).to eql 2
      expect(_participant.contacts.count).to eql 2

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      address = _participant.addresses.last

      delete "/api/v1/participant/#{_participant.member_id}/addresses/#{address.id}"

      participant = Participant.find(id: _participant.id)

      expect(participant.addresses.count).to eql 1
      expect(participant.address.street).to eql "some road"
      expect(participant.address.city).to eql "City"

      contact_id = _participant.contacts.last.id

      delete "/api/v1/participant/#{_participant.member_id}/contacts/#{contact_id}"
      participant = Participant.find(id: _participant.id)

      expect(participant.contacts.count).to eql 1
      expect(participant.contact.contact_type).to eql "Home"
   end

   it "should be able to delete user" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.addresses.count).to eql 2
      expect(_participant.contacts.count).to eql 2

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      delete "/api/v1/participant/#{_participant.member_id}"

      expect(Participant.find(id: _participant.id)).to eql nil
      expect(Address.where(participant_uuid: _participant.uuid).count).to eql 0
      expect(ContactNumber.where(participant_uuid: _participant.uuid).count).to eql 0
   end

   it "should be able to delete multiple participants as bulk" do
      Participant.all.each { |p| p.destroy }

      user1 = Participant.create(first_name: "Saravana", last_name: "Balaraj", member_id: "11111111", email: "sgsaravana@gmail.com", gender: "Male", center_code: "1017", uuid: SecureRandom.uuid)
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", member_id: "22222222", email: "psenthu@gmail.com", gender: "Male", center_code: "1017", uuid: SecureRandom.uuid)
      user3 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", member_id: "33333333", email: "psenthu@gmail.com", gender: "Male", center_code: "1018", uuid: SecureRandom.uuid)
      user4 = Participant.create(first_name: "Senthuran", last_name: "P", member_id: "44444444", email: "psenthu@gmail.com", gender: "Male", center_code: "1018", uuid: SecureRandom.uuid)

      expect(Participant.count).to eql 4

      post "/api/v1/participant/bulk_delete", {
         participants: [user1.member_id, user2.member_id, user3.member_id]
      }

      response = JSON.parse(last_response.body)

      expect(response['count']).to eql 3
      expect(Participant.count).to eql 1
   end

   it "should be able to add comment for participant" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      post "/api/v1/participant/#{_participant.member_id}/comments", {
         comment: {
            content: "test comment",
            created_by: "sgsaravana@gmail.com"
         }
      }

      expect(_participant.comments.count).to eql 1
   end

   it "should be able to edit comment" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      post "/api/v1/participant/#{_participant.member_id}/comments", {
         comment: {
            content: "first comment"
         }
      }

      expect(_participant.comments.all[0].content).to eql "first comment"

      put "/api/v1/participant/#{_participant.member_id}/comments/#{_participant.comments.all[0][:id]}", {
         comment: {
            content: "edited comment"
         }
      }

      expect(_participant.comments.all[0].content).to eql "edited comment"
   end

   it "should be able to delete comment" do
      post '/api/v1/participant',
         participant: {first_name:"Saravana", email: "sgsaravana@gmail.com", uuid: SecureRandom.uuid},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG"}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453"},
            {contact_type: "Mobile", value: "454625363", is_default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      post "/api/v1/participant/#{_participant.member_id}/comments", {
         comment: {
            content: "first comment",
            created_by: "sgsaravana@gmail.com"
         }
      }

      post "/api/v1/participant/#{_participant.member_id}/comments", {
         comment: {
            content: "second comment",
            created_by: "sgsaravana@gmail.com"
         }
      }

      post "/api/v1/participant/#{_participant.member_id}/comments", {
         comment: {
            content: "third comment",
            created_by: "sgsaravana@gmail.com"
         }
      }

      expect(_participant.comments.count).to eql 3

      comment_id = _participant.comments.last.id

      delete "/api/v1/participant/#{_participant.member_id}/comments/#{comment_id}"

      expect(_participant.comments.count).to eql 2
   end

   it "should be able to merge participants" do
      # Create few temp users to be added as friends
      user1 = Participant.create(first_name: "Saravana", last_name: "Balaraj", member_id: "11111111", email: "sgsaravana@gmail.com", gender: "Male", center_code: "1017", uuid: SecureRandom.uuid)
      user2 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", member_id: "22222222", email: "psenthu@gmail.com", gender: "Male", center_code: "1017", uuid: SecureRandom.uuid)
      user3 = Participant.create(first_name: "Senthuran", last_name: "Ponnampalam", member_id: "33333333", email: "psenthu@gmail.com", gender: "Male", center_code: "1018", uuid: SecureRandom.uuid)
      user4 = Participant.create(first_name: "Senthuran", last_name: "P", member_id: "44444444", email: "psenthu@gmail.com", gender: "Male", center_code: "1018", uuid: SecureRandom.uuid)
      # Create master record with contact and addresses
      post '/api/v1/participant',
         {
            participant: {first_name:"Saravana", last_name:"Balaraj", email:"sgsaravana@gmail.com", gender:"Male"},
            addresses: [
               {street: "some road", city: "City", country: "SG"},
               {street: "another one", city: "SG", country: "SG"}
             ],
             contacts: [
               {contact_type: "Home", value: "3342453"},
               {contact_type: "Mobile", value: "454625363", is_default: true}
             ],
             friends: [user1.member_id, user2.member_id]
         }, {'HTTP_TOKEN' => @token}

      response    = JSON.parse(last_response.body)
      participant = Participant.find(member_id: response['member_id'])
      # Add comment for master record
      post "/api/v1/participant/#{participant.member_id}/comments", {
         comment: {
            content: "test comment one for master record",
            created_by: "sgsaravana@gmail.com"
         }
      }

      # Create first duplicate record with contact and addresses
      post '/api/v1/participant',
         {
            participant: {first_name:"Saravana", last_name:"B", email:"sgravana@gmail.com", gender:"Male"},
            addresses: [
               {street: "some road", city: "City", country: "SG"},
               {street: "another one", city: "SG", country: "SG"}
             ],
             contacts: [
               {contact_type: "Home", value: "86286022"}
             ],
             friends: [user2.member_id, user3.member_id]
         }, {'HTTP_TOKEN' => @token}

      response = JSON.parse(last_response.body)
      dup1     = Participant.find(member_id: response['member_id'])
      # Add comment for first duplicate record
      post "/api/v1/participant/#{dup1.member_id}/comments", {
         comment: {
            content: "test comment one for first duplicate",
            created_by: "sgsaravana@gmail.com"
         }
      }

      # Create second duplicate record with contact and addresses
      post '/api/v1/participant',
         {
            participant: {first_name:"Nithya Shreshthananda", last_name:"", email:"sgravana@gmail.com", gender:"Male"},
            addresses: [
               {street: "another one", city: "SG", country: "SG"}
             ],
             contacts: [
               {contact_type: "Home", value: "98897484"}
             ],
             friends: [user3.member_id, user4.member_id]
         }, {'HTTP_TOKEN' => @token}

      response = JSON.parse(last_response.body)
      dup2     = Participant.find(member_id: response['member_id'])
      # Add comment for the second duplicate record
      post "/api/v1/participant/#{dup2.member_id}/comments", {
         comment: {
            content: "test comment one for the second duplicate",
            created_by: "sgsaravana@gmail.com"
         }
      }

      put "/api/v1/participant/#{participant.member_id}/merge/#{participant.member_id}", {
         merge_data: {
            master_record: {first_name: "Nithya Shreshthananda", last_name: ""},
            address_ids: [dup2.addresses.last.id],
            contact_ids: [dup1.contacts.first.id, dup2.contacts.first.id],
            merge_ids: [dup1.member_id, dup2.member_id]
         }
      }

      response = JSON.parse(last_response.body)
      # puts response.inspect

      merged = Participant.find(member_id: response['member_id'])

      expect(merged.first_name).to eql "Nithya Shreshthananda"
      expect(merged.contacts.count).to eql 4
      expect(merged.addresses.count).to eql 3
      expect(merged.comments.count).to eql 3
      expect(merged.friends.count).to eql 4
   end

end

