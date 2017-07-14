class Solution < ApplicationRecord

  belongs_to :user
  belongs_to :exercise
  belongs_to :approved_by, class_name: "User", optional: true

  has_many :iterations
  has_many :discussion_posts, through: :iterations

  has_many :mentorships, class_name: "SolutionMentorship"
  has_many :mentors, through: :mentorships, source: :user

  def self.completed
    where.not(completed_at: nil)
  end

  def self.not_completed
    where(completed_at: nil)
  end

  def self.published
    where.not(published_at: nil)
  end

  def approved?
    !!approved_by
  end

  # TODO - Check this is being set somewhere
  def cloned?
    !!cloned_at
  end

  def in_progress?
    cloned? || iterations.size > 0
  end

  def published?
    !!published_at
  end

  def completed?
    !!completed_at
  end

  def instructions
    git_exercise.instructions
  end

  def test_suite
    git_exercise.test_suite
  end

  def git_exercise
    @git_exercise ||= GitExercise.new(exercise, git_sha)
  end
end