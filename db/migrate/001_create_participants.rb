Sequel.migration do
  up do
    create_table :participants do
      primary_key :id
      String :first_name, :collate => "UTF8_GENERAL_CI"
      String :last_name, :collate => "UTF8_GENERAL_CI"
      String :email, :collate => "UTF8_GENERAL_CI"
      String :gender
      String :other_names, :collate => "UTF8_GENERAL_CI"
      Date :dob
      String :member_id
      String :uuid
      Integer :default_contact
      Integer :default_address
      Text :notes, :collate => "UTF8_GENERAL_CI"
      Text :participant_attributes
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table :participants
  end
end
