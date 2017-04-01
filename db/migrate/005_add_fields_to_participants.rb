Sequel.migration do
  up do
    alter_table :participants do
      add_column :created_by, String
    end
  end

  down do
    alter_table :participants do
      drop_column :created_by
    end
  end
end
