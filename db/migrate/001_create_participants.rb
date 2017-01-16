Sequel.migration do
  up do
    create_table :participants do
      primary_key :id
      String :first_name
      String :last_name
      String :email
      String :gender
      String :other_names
      Date :dob
      String :member_id
      String :uuid
      Integer :default_contact
      Integer :default_address
      Text :notes
      Text :participant_attributes
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table :participants
  end
end
