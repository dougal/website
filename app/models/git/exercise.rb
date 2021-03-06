class Git::Exercise
  attr_reader :track, :git_slug, :git_sha
  def initialize(exercise, git_slug, git_sha)
    @track = exercise.track
    @git_slug = git_slug
    @git_sha = git_sha
  end

  def instructions
    ParseMarkdown.(exercise_reader.readme)
  end

  def test_suite
    exercise_reader.tests
  end

  private

  def exercise_reader
    @repo_exercise ||= repo.exercise(git_slug, git_sha)
  end

  def repo_url
    track.repo_url
  end

  def repo
    Git::ExercismRepo.new(repo_url)
  end
end
