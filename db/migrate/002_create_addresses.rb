Sequel.migration do
  up do
    create_table :addresses do
      primary_key :id
      String :participant_uuid
      Text :street
      String :city
      String :state
      String :postal_code
      String :country
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table :addresses
  end
end
