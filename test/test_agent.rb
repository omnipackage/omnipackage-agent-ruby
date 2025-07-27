# frozen_string_literal: true

require 'test_helper'

describe ::OmnipackageAgent do
  it 'has default config' do
    assert ::OmnipackageAgent::Config.get
  end

  it 'has default distros config' do
    assert_operator ::OmnipackageAgent::Distro.to_a.size, :>, 20
  end
end
