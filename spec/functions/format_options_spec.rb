# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::format_options' do
  it 'returns an empty string for undef' do
    expect(subject).to run.with_params(nil).and_return('')
  end

  it 'returns an empty string for an empty array' do
    expect(subject).to run.with_params([]).and_return('')
  end

  it 'prefixes a string with a hyphen' do
    expect(subject).to run.with_params('rw').and_return('-rw')
  end

  it 'joins and prefixes an array of options' do
    expect(subject).to run.with_params(%w[rw noexec]).and_return('-rw,noexec')
  end

  it 'tolerates a user-provided leading hyphen on a string' do
    expect(subject).to run.with_params('-rw').and_return('-rw')
  end

  it 'tolerates a user-provided leading hyphen on an array' do
    expect(subject).to run.with_params(%w[-rw noexec]).and_return('-rw,noexec')
  end

  it 'does not hyphenate internally' do
    expect(subject).to run.with_params('rsize=4k,intr').and_return('-rsize=4k,intr')
  end
end
