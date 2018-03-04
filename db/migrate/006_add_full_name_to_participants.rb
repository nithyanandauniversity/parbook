Sequel.migration do
  up do
    alter_table :participants do
      add_column :full_name, String
    end
  end

  down do
    alter_table :participants do
      drop_column :full_name
    end
  end
end
