require 'rails_helper'

RSpec.describe TaxonomySeeder do
  describe '.seed!' do
    before do
      # Clear topics before testing seeder
      Topic.delete_all
    end

    it 'creates all topics from empty state' do
      expect { TaxonomySeeder.seed! }.to change(Topic, :count).by(TaxonomySeeder::TOPICS.count)
    end

    it 'does not duplicate topics on repeated runs' do
      TaxonomySeeder.seed!
      expect { TaxonomySeeder.seed! }.not_to change(Topic, :count)
    end

    it 'calls Tag.seed_defaults!' do
      expect(Tag).to receive(:seed_defaults!).once
      TaxonomySeeder.seed!
    end

    it 'creates specific topics' do
      TaxonomySeeder.seed!
      expect(Topic.pluck(:name)).to include('General', 'Academics', 'Housing', 'Wellness', 'Career', 'Campus Life')
    end
  end

  describe '#seed!' do
    before do
      Topic.delete_all
    end

    it 'can be called via instance method' do
      seeder = TaxonomySeeder.new
      expect { seeder.seed! }.to change(Topic, :count)
    end
  end
end
