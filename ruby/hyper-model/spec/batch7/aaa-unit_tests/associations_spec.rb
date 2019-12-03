require 'spec_helper'

describe 'Association Reflection', js: true do
  it 'only knows associations defined in itself or its parent' do
    expect_evaluate_ruby do
      Dog.reflect_on_all_associations.map(&:attribute)
    end.to eq(%w[owner bones])

    expect_evaluate_ruby do
      Cat.reflect_on_all_associations.map(&:attribute)
    end.to eq(%w[owner scratching_posts])

    expect_evaluate_ruby do
      Pet.reflect_on_all_associations.map(&:attribute)
    end.to eq(%w[owner])
  end
end
