class CreateBrothers < ActiveRecord::Migration
  def change
    create_table :brothers do |t|
      t.text :screen_name

      t.timestamps
    end
  end
end
