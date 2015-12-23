class CreateUsers < ActiveRecord::Migration
    def up
        create_table :users, id: false do |t|
            t.string :uid, null: false
            t.string :profileimage, null: false
            t.string :tid, default: "0"
            t.text :settings
        end
        execute "ALTER TABLE users ADD PRIMARY KEY (uid);"
    end

    def down
        drop_table :users
    end
end
