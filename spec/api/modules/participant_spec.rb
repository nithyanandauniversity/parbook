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
            {contact_type: "Mobile", value: "454625363", default: true}
         ]

      resp = JSON.parse(last_response.body)
      participant = Participant.find(id: resp["id"])

      expect(participant.address.street).to eql("some road")
      expect(participant.contact.contact_type).to eql("Mobile")
      expect(participant.contact.value).to eql("454625363")
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
            {contact_type: "Mobile", value: "454625363", default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.first_name).to eql("Saravana")

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      put "/api/v1/participant/#{_participant.id}",
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
            {contact_type: "Mobile", value: "454625363", default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      put "/api/v1/participant/#{_participant.id}",
         participant: {first_name: "Saravana"},
         addresses: [
            {street: "some road", city: "City", country: "SG"},
            {street: "another one", city: "SG", country: "SG", default: true}
         ],
         contacts: [
            {contact_type: "Home", value: "3342453", default: true},
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
            {contact_type: "Mobile", value: "454625363", default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.addresses.count).to eql 2
      expect(_participant.contacts.count).to eql 2

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      address_id = _participant.addresses.last.id

      delete "/api/v1/participant/#{_participant.id}/address/#{address_id}"

      participant = Participant.find(id: _participant.id)

      expect(participant.addresses.count).to eql 1
      expect(participant.address.street).to eql "some road"
      expect(participant.address.city).to eql "City"

      contact_id = _participant.contacts.last.id

      delete "/api/v1/participant/#{_participant.id}/contact/#{contact_id}"
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
            {contact_type: "Mobile", value: "454625363", default: true}
         ]

      resp = JSON.parse(last_response.body)
      _participant = Participant.find(id: resp["id"])

      expect(_participant.addresses.count).to eql 2
      expect(_participant.contacts.count).to eql 2

      expect(_participant.address.street).to eql("some road")
      expect(_participant.contact.contact_type).to eql("Mobile")
      expect(_participant.contact.value).to eql("454625363")

      delete "/api/v1/participant/#{_participant.id}"

      expect(Participant.find(id: _participant.id)).to eql nil
      expect(Address.where(participant_uuid: _participant.uuid).count).to eql 0
      expect(ContactNumber.where(participant_uuid: _participant.uuid).count).to eql 0

   end

end

