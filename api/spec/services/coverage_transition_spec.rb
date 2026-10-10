require 'rails_helper'
RSpec.describe Coverage::StateEngine do
  it 'requires two probes before a proposed covered skill can advance past initiated' do
    expect(described_class.resolve_state(current_state:'not_yet',proposed_state:'covered',probe_count:1)).to eq('initiated')
    expect(described_class.resolve_state(current_state:'not_yet',proposed_state:'covered',probe_count:2)).to eq('covered')
  end
  it 'cannot erase persisted coverage with a regressive or unknown model update' do
    expect(described_class.resolve_state(current_state:'covered',proposed_state:'partial',probe_count:3)).to eq('covered')
    expect(described_class.resolve_state(current_state:'partial',proposed_state:'invented',probe_count:3)).to eq('partial')
  end
end
