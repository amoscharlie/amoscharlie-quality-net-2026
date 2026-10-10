class AddAudioConnectionIdToSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :sessions, :audio_connection_id, :uuid
  end
end
