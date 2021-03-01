class AddAttributesToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :guest_rating, :decimal, :null => true, inclusion: { in: 0...5 }, precision: 10, scale: 2
    add_column :users, :host_rating, :decimal, :null => true, inclusion: { in: 0...5 }, precision: 10, scale: 2
    add_column :users, :image_url, :string, :null => true
    #Ex:- add_column("admin_users", "username", :string, :limit =>25, :after => "email")
  end
end
