Sequel.migration do
  up do
    create_table :contact_numbers do
      primary_key :id
      String :participant_uuid
      String :contact_type
      String :value
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table :contact_numbers
  end
end
