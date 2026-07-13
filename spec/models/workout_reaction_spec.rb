require "rails_helper"

RSpec.describe WorkoutReaction do
  it "is invalid without an emoji" do
    expect(build(:workout_reaction, emoji: nil)).not_to be_valid
  end

  it "rejects a second reaction from the same author on the same check-in at the DB level" do
    check_in = create(:workout_check_in, :completed)
    author = create(:user)
    create(:workout_reaction, workout_check_in: check_in, author: author)

    expect do
      create(:workout_reaction, workout_check_in: check_in, author: author)
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows different authors to react to the same check-in" do
    check_in = create(:workout_check_in, :completed)

    expect do
      create(:workout_reaction, workout_check_in: check_in)
      create(:workout_reaction, workout_check_in: check_in)
    end.not_to raise_error
  end

  it "survives its author being deleted" do
    reaction = create(:workout_reaction)
    reaction.author.destroy!

    expect(reaction.reload.author_id).to be_nil
  end
end
