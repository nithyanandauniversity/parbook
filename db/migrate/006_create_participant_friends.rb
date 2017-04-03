Sequel.migration do
  up do
    create_table :participant_friends do
      primary_key :id
      String :participant_id
      String :friend_id
    end
  end

  down do
    drop_table :participant_friends
  end
end
