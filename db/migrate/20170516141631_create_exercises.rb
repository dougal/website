class CreateExercises < ActiveRecord::Migration[5.1]
  def change
    create_table :exercises do |t|
      t.bigint :track_id, null: false
      t.bigint :unlocked_by_id, null: true
      t.string :uuid, null: false
      t.string :slug, null: false

      t.string :title, null: false
      t.boolean :core, default: false, null: false
      t.boolean :active, default: false, null: false

      t.integer :difficulty, null: false, default: 1
      t.integer :length, null: false, default: 1

      t.integer :position, null: true

      t.timestamps
    end

    add_foreign_key :exercises, :tracks
    add_foreign_key :exercises, :exercises, column: :unlocked_by_id
  end
end