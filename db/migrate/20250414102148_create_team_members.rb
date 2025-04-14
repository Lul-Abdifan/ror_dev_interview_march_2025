class CreateTeamMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :team_members do |t|
      t.references :team, null: false, foreign_key: true
      t.string :slot
      t.string :external_id
      t.string :external_api
      t.string :external_url

      t.timestamps
    end
  end
end
