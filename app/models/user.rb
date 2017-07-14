class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:github]

  has_many :auth_tokens
  has_one :communication_preferences

  has_one :profile
  has_many :notifications

  has_many :user_tracks
  has_many :tracks, through: :user_tracks
  has_many :solutions
  has_many :iterations, through: :solutions

  has_many :track_mentorships
  has_many :mentored_tracks, through: :track_mentorships, source: :track

  has_many :solution_mentorships
  has_many :mentored_solutions, through: :solution_mentorships, source: :solution

  after_create do
    create_communication_preferences
  end

  # TODO
  def avatar_url
    "http://lorempixel.com/400/400/"
  end

  def unlocked_track?(track)
    user_tracks.where(track_id: track.id).exists?
  end

  def mentor?
    track_mentorships.exists?
  end

  def mentoring_track?(track)
    track_mentorships.where(track_id: track.id).exists?
  end

  def mentoring_solution?(solution)
    solution_mentorships.where(solution_id: solution.id).exists?
  end
end