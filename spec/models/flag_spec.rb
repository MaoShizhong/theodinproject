require 'rails_helper'

RSpec.describe Flag do
  subject(:flag) { described_class.new }

  it { is_expected.to belong_to(:flagger) }
  it { is_expected.to belong_to(:project_submission) }
  it { is_expected.to belong_to(:resolved_by).optional }

  it { is_expected.to validate_presence_of(:reason) }
  it { is_expected.to define_enum_for(:status).with_values(%i[active resolved]) }

  it do
    expect(flag)
      .to define_enum_for(:reason)
      .with_values(broken: 10, insecure: 20, spam: 30, inappropriate: 40, other: 50)
  end

  it do
    expect(flag).to define_enum_for(:action_taken)
      .with_values(%i[pending dismiss ban removed_project_submission notified_user])
  end

  describe '#resolved_by_id' do
    context 'when the flag is resolved' do
      it 'validates the presence of resolved_by_id' do
        flag = build(:flag, :resolved, resolved_by_id: nil)

        expect(flag).to validate_presence_of(:resolved_by_id)
      end
    end

    context 'when the flag is not resolved' do
      it 'does not validate the presence of resolved_by_id' do
        flag = build(:flag, resolved_by_id: nil)

        expect(flag).not_to validate_presence_of(:resolved_by_id)
      end
    end
  end

  describe '.by_status' do
    context "when status is 'active'" do
      it 'returns active flags' do
        active_flag = create(:flag, :active)
        resolved_flag = create(:flag, :resolved)

        expect(described_class.by_status('active')).to contain_exactly(active_flag)
      end
    end

    context "when status is 'resolved'" do
      it 'returns resolved flags' do
        resolved_flag = create(:flag, :resolved)
        active_flag = create(:flag, :active)

        expect(described_class.by_status(:resolved)).to contain_exactly(resolved_flag)
      end
    end
  end

  describe '.count_for' do
    context "when the given status is 'active'" do
      it 'returns the count of active flags' do
        active_flag = create(:flag, :active)
        another_active_flag = create(:flag, :active)
        resolved_flag = create(:flag, :resolved)

        expect(described_class.count_for(:active)).to eq(2)
      end
    end

    context "when the given status is 'resolved'" do
      it 'returns the count of resolved flags' do
        resolved_flag = create(:flag, :resolved)
        active_flag = create(:flag, :active)
        another_active_flag = create(:flag, :active)

        expect(described_class.count_for(:resolved)).to eq(1)
      end
    end
  end

  describe '.ordered_by_most_recent' do
    it 'returns flags ordered by most recently created' do
      created_three_days_ago = create(:flag, created_at: 3.days.ago)
      created_two_days_ago = create(:flag, created_at: 2.days.ago)
      created_one_day_ago = create(:flag, created_at: 1.day.ago)

      expect(described_class.ordered_by_most_recent).to eq(
        [created_one_day_ago, created_two_days_ago, created_three_days_ago]
      )
    end
  end

  describe '#resolve' do
    it 'updates the status and action taken of the flag' do
      admin_user = create(:admin_user)

      expect { flag.resolve(action_taken: :dismiss, resolved_by: admin_user) }
        .to change { flag.status }.from('active').to('resolved')
        .and change { flag.action_taken }.from('pending').to('dismiss')
    end

    it 'sets who resolved the flag' do
      resolved_by = create(:admin_user)

      flag.resolve(action_taken: :dismiss, resolved_by:)

      expect(flag.resolved_by).to eq(resolved_by)
    end
  end

  describe '#action_taken_value' do
    it 'returns a value object for the action_taken' do
      flag.action_taken = 'dismiss'

      expect(flag.action_taken_value).to be_a(Flags::Action)
    end
  end
end
