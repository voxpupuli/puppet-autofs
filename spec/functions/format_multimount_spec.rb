# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::format_multimount' do
  # Each argument is an Autofs::Multimount: { 'mountpoint' => ..., 'options' => ...,
  # 'fs' => ... }.  An omitted 'mountpoint' mounts at the automount point.
  let(:mounts_base) do
    [
      { 'mountpoint' => nil, 'fs' => 'nfs1:/d1' },
      { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs1:/d2' },
    ]
  end

  it 'emits source first, then prepends offset and per-mountpoint options' do
    expect(subject)
      .to run.with_params(mounts_base)
      .and_return('nfs1:/d1 /docs -ro nfs1:/d2')
  end

  it 'renders an explicit base offset (/) as-is' do
    expect(subject)
      .to run.with_params([{ 'mountpoint' => '/', 'fs' => 'nfs1:/d1' }])
      .and_return('/ nfs1:/d1')
  end

  it 'emits a non-slash-prefixed mountpoint verbatim (as-is)' do
    expect(subject)
      .to run.with_params(
        [{ 'mountpoint' => 'docs', 'options' => 'ro', 'fs' => 'nfs1:/d2' }],
      )
             .and_return('docs -ro nfs1:/d2')
  end

  it 'joins multiple filesystems with single spaces' do
    expect(subject)
      .to run.with_params(
        [
          { 'mountpoint' => '/',        'fs' => 'nfs1:/d1' },
          { 'mountpoint' => '/usr',     'fs' => 'nfs1:/d2' },
          { 'mountpoint' => '/home', 'options' => %w[rw noexec], 'fs' => 'nfs1:/d3' },
        ],
      )
             .and_return('/ nfs1:/d1 /usr nfs1:/d2 /home -rw,noexec nfs1:/d3')
  end

  it 'omits the offset token when mountpoint is not given' do
    expect(subject)
      .to run.with_params([{ 'options' => 'rw', 'fs' => 'nfs1:/d1' }])
      .and_return('-rw nfs1:/d1')
  end

  it 'escapes a source containing spaces, per format_fs' do
    expect(subject)
      .to run.with_params([{ 'mountpoint' => '/data', 'fs' => 'host:/has space' }])
      .and_return(%(/data "host:/has space"))
  end
end
