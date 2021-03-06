require 'test_helper'

class SelectSuggestedSolutionsForMentorTest < ActiveSupport::TestCase
  test "selects only mentored tracks" do
    mentor = create(:user)
    track1 = create :track
    track2 = create :track
    track3 = create :track
    mentee = create_mentee([track1, track2, track3])

    solution1 = create(:solution,
                       exercise: create(:exercise, track: track1),
                       user: mentee)
    solution2 = create(:solution,
                       exercise: create(:exercise, track: track2),
                       user: mentee)
    solution3 = create(:solution,
                       exercise: create(:exercise, track: track3),
                       user: mentee)
    create :iteration, solution: solution1
    create :iteration, solution: solution2
    create :iteration, solution: solution3

    create :track_mentorship, user: mentor, track: track1
    create :track_mentorship, user: mentor, track: track2

    assert_equal [solution1, solution2].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "does not select solutions you already mentor" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track),
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track),
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution
    create :solution_mentorship, user: mentor, solution: bad_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "filters by track" do
    mentor, track1 = create_mentor_and_track
    track2 = create :track
    create :track_mentorship, user: mentor, track: track2
    mentee = create_mentee([track1, track2])

    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track2),
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track1),
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor, filtered_track_ids: track1.id).sort
  end

  test "filters by exercise" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    bad_exercise = create(:exercise, track: track)
    good_exercise = create(:exercise, track: track)
    bad_solution = create(:solution,
                          exercise: bad_exercise,
                          user: mentee)
    good_solution = create(:solution,
                           exercise: good_exercise,
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor, filtered_exercise_ids: good_exercise.id).sort
  end

  test "only selects solutions that have an iteration" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track),
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track),
                           user: mentee)
    create :iteration, solution: good_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "does not select solutions with >=3 mentors" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    # Temporary change: >=3 to >=1
    # For >=3 mentors, change the values below to 1 and 0 respective
    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track),
                          num_mentors: 1,
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track),
                           num_mentors: 0,
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "does not select approved solutions" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track),
                          approved_by: create(:user),
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track),
                           approved_by: nil,
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "does not select completed solutions" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track),
                          completed_at: DateTime.now - 1.minute,
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track),
                           completed_at: nil,
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "does not select ignored solutions" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    bad_solution = create(:solution,
                          exercise: create(:exercise, track: track),
                          user: mentee)
    good_solution = create(:solution,
                           exercise: create(:exercise, track: track),
                           user: mentee)
    create :iteration, solution: good_solution
    create :iteration, solution: bad_solution
    create :ignored_solution_mentorship, solution: bad_solution, user: mentor

    assert_equal [good_solution].sort, SelectSuggestedSolutionsForMentor.(mentor).sort
  end

  test "puts exercises in standard mode first" do
    mentor = create(:user)
    mentee = create(:user)
    track = create(:track)
    create(:track_mentorship, user: mentor, track: track)

    standard_exercise = create(:exercise, track: track)
    standard_solution = create(:solution, exercise: standard_exercise, user: mentee, independent_mode: false)

    independent_exercise = create(:exercise, track: track)
    independent_solution = create(:solution,
                                  exercise: independent_exercise,
                                  user: mentee,
                                  independent_mode: true)

    [standard_solution, independent_solution].each do |solution|
      create :iteration, solution: solution
    end

    expected = [standard_solution, independent_solution]
    actual = SelectSuggestedSolutionsForMentor.(mentor)
    assert_equal expected.map(&:id), actual.map(&:id)
  end

  test "puts core exercises first" do
    mentor, track = create_mentor_and_track
    mentee = create_mentee([track])

    side_solution = create(:solution,
                           exercise: create(:exercise, track: track, core: false),
                           user: mentee)
    core_solution = create(:solution,
                           exercise: create(:exercise, track: track, core: true),
                           user: mentee)
    [core_solution, side_solution].each do |solution|
      create :iteration, solution: solution
    end

    assert_equal(
      [core_solution, side_solution],
      SelectSuggestedSolutionsForMentor.(mentor)
    )
  end

  test "orders correctly" do
    Timecop.freeze do
      mentor, track = create_mentor_and_track
      independent_user = create :user
      mentored_user = create :user
      core_exercise = create(:exercise, track: track, core: true)
      side_exercise = create(:exercise, track: track, core: false)

      independent_solution = create(:solution,
                                    exercise: create(:exercise, track: track, core: true),
                                    num_mentors: 0,
                                    last_updated_by_user_at: DateTime.now,
                                    user: independent_user,
                                    independent_mode: true)

      unmentored_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 0,
                                        last_updated_by_user_at: DateTime.now,
                                        user: mentored_user)

      unmentored_side_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: false),
                                        num_mentors: 0,
                                        last_updated_by_user_at: DateTime.now,
                                        user: mentored_user)

      mentored_1_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 1,
                                        last_updated_by_user_at: DateTime.now,
                                        user: mentored_user)

      mentored_2_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 2,
                                        last_updated_by_user_at: DateTime.now,
                                        user: mentored_user)

      unmentored_older_legacy_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 0,
                                        created_at: Exercism::V2_MIGRATED_AT - 1.hour,
                                        last_updated_by_user_at: Time.now - 30.seconds,
                                        user: mentored_user)

      unmentored_newer_legacy_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 0,
                                        created_at: Exercism::V2_MIGRATED_AT - 1.hour,
                                        last_updated_by_user_at: Time.now + 30.seconds,
                                        user: mentored_user)

      unmentored_dead_legacy_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 0,
                                        created_at: Exercism::V2_MIGRATED_AT - 1.hour,
                                        last_updated_by_user_at: Exercism::V2_MIGRATED_AT - 1.hour,
                                        user: mentored_user)


      old_unmentored_core_solution = create(:solution,
                                        exercise: create(:exercise, track: track, core: true),
                                        num_mentors: 0,
                                        last_updated_by_user_at: Time.now - 1.day,
                                        user: mentored_user)

      [
        independent_solution,
        old_unmentored_core_solution,
        unmentored_core_solution,
        unmentored_side_solution,
        unmentored_older_legacy_core_solution,
        unmentored_newer_legacy_core_solution,
        mentored_1_core_solution,
        mentored_2_core_solution,
        unmentored_dead_legacy_core_solution
      ].each do |solution|
        create :iteration, solution: solution
      end

      expected = [
        old_unmentored_core_solution,
        unmentored_core_solution,
        unmentored_side_solution,
        unmentored_older_legacy_core_solution,
        unmentored_newer_legacy_core_solution,
        independent_solution,
        unmentored_dead_legacy_core_solution,

        # We are currently not showing any solutions
        # with >=1 mentor. Uncomment these again when/if 
        # we change this back to >=3 mentors.
        #mentored_1_core_solution, 
        #mentored_2_core_solution,
      ]
      actual = SelectSuggestedSolutionsForMentor.(mentor)

      assert_equal expected.map(&:id), actual.map(&:id)
    end
  end

  def create_mentor_and_track
    mentor = create :user
    track = create :track
    create :track_mentorship, user: mentor, track: track
    [mentor, track]
  end

  def create_mentee(tracks)
    mentee = create(:user)
    tracks.each { |track| create(:user_track, track: track, user: mentee) }

    mentee
  end
end
