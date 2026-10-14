# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::format_fs' do
  it 'returns a simple string unchanged' do
    expect(subject).to run.with_params('server:/export/path').and_return('server:/export/path')
  end

  it 'quotes and escapes a string with whitespace' do
    expect(subject).to run.with_params('server:/export/my path').and_return('"server:/export/my path"')
  end

  it 'quotes and escapes a string with quotes' do
    expect(subject).to run.with_params('server:/export/path"with"quotes').and_return('"server:/export/path\\"with\\"quotes"')
  end

  it 'quotes and escapes a string with both whitespace and quotes' do
    expect(subject).to run.with_params('server:/export/my path"with"quotes').and_return('"server:/export/my path\\"with\\"quotes"')
  end

  it 'leaves backslashes unchanged if no quotes needed' do
    expect(subject).to run.with_params('server:/export/path\\with\\backslashes').and_return('server:/export/path\\with\\backslashes')
  end

  it 'handles an array of simple strings' do
    expect(subject).to run.with_params(['server1:/path', 'server2:/path']).and_return('server1:/path server2:/path')
  end

  it 'handles an array with whitespace' do
    expect(subject).to run.with_params(['server1:/my path', 'server2:/other']).and_return('"server1:/my path" server2:/other')
  end

  it 'handles a single-item array' do
    expect(subject).to run.with_params(['server:/path']).and_return('server:/path')
  end
end
