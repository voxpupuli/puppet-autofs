# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::format_key' do
  it 'returns a simple key unchanged' do
    expect(subject).to run.with_params('user1').and_return('user1')
  end

  it 'returns a key with whitespace quoted' do
    expect(subject).to run.with_params('my key').and_return('"my key"')
  end

  it 'returns a key with quotes properly escaped' do
    expect(subject).to run.with_params('key"with"quotes').and_return('"key\\"with\\"quotes"')
  end

  it 'returns a key with leading slash' do
    expect(subject).to run.with_params('/absolute/path').and_return('/absolute/path')
  end

  it 'returns a key with tab' do
    expect(subject).to run.with_params("key\twith\ttab").and_return('"key\twith\ttab"')
  end

  it 'returns a key with space at start' do
    expect(subject).to run.with_params(' key').and_return('" key"')
  end

  it 'returns a key with space at end' do
    expect(subject).to run.with_params('key ').and_return('"key "')
  end
end
