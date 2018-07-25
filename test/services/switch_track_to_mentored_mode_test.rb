require 'test_helper'

class SwitchTrackToMentoredModeTest < ActiveSupport::TestCase
  test "sets uncompleted solutions to independent mode" do
    user = create :user
    track = create :track
    completed_solution = create :solution, user: user, exercise: create(:exercise, track: track), independent_mode: true, completed_at: DateTime.now
    uncompleted_solution = create :solution, user: user, exercise: create(:exercise, track: track), independent_mode: true, completed_at: nil
    user_track = create :user_track, user: user, track: track

    SwitchTrackToMentoredMode.(user, track)

    [user_track, completed_solution, uncompleted_solution].each(&:reload)

    refute user_track.independent_mode?
    assert completed_solution.independent_mode
    refute uncompleted_solution.independent_mode
  end
end

