class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.text :screen_name
      t.text :status

      t.timestamps
    end
  end
end
