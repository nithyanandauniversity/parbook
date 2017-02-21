Sequel.migration do
  up do
    create_table :comments do
      primary_key :id
      String :participant_uuid
      String :event_uuid
      Text :content
      String :created_by
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table :comments
  end
end
