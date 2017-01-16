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
         addresses: [{street: "some road", city: "City", country: "SG"}],
         contacts: [{contact_type: "Mobile", value: "454625363"}]

      resp = JSON.parse(last_response.body)
      participant = Participant.find(id: resp["id"])

      expect(participant.addresses.count).to eql 1
      expect(participant.contacts.count).to eql 1

      # expect(Address.find(id:resp["id"]).center[:name]).to eql "Yogam"
   end

   # it "should be able to edit center" do
   #    center = Center.create(name: "Yogam", location: "Singapore")

   #    put "/api/v1/center/#{center.id}", center: {name: "Yogam Center"}

   #    resp = JSON.parse(last_response.body)

   #    expect(resp["name"]).to eql("Yogam Center")
   # end

   # it "should be able to edit center address" do

   #    center = Center.create(name: "Yogam", location: "Singapore")
   #    post "/api/v1/center/#{center.id}/address", address: {address:"11 Street", city:"Singapore", country: "Singapore"}

   #    address = JSON.parse(last_response.body)

   #    put "/api/v1/center/#{center.id}/address/#{address['id']}", address: {address: "411 Race course Road"}

   #    response = JSON.parse(last_response.body)

   #    expect(response["address"]).to eql "411 Race course Road"
   #    expect(response["city"]).to eql "Singapore"

   #    expect(Address.find(id:response["id"]).center[:name]).to eql "Yogam"
   # end

   # it "should be able to delete center" do
   #    center = Center.create(name: "Yogam", location: "Singapore")
   #    centerID = center.id

   #    delete "/api/v1/center/#{center.id}"

   #    expect(Center.find(id: center.id)).to eql nil
   # end

   # it "should be able to delete center address" do
   #    center = Center.create(name: "Yogam", location: "Singapore")
   #    post "/api/v1/center/#{center.id}/address", address: {address:"11 Street", city:"Singapore", country: "Singapore"}

   #    address = JSON.parse(last_response.body)
   #    expect(Center.find(id: center.id).addresses.length).to eql 1

   #    delete "/api/v1/center/#{center.id}/address/#{address['id']}"

   #    expect(Center.find(id: center.id).addresses.length).to eql 0
   # end

end

