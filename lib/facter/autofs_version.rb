# frozen_string_literal: true

Facter.add(:autofs_version) do
  confine kernel: :Linux
  confine { Facter::Core::Execution.which('automount') }
  setcode do
    autofs_version_command = 'automount -V 2>&1'
    autofs_version = Facter::Core::Execution.execute(autofs_version_command)
    %r{Linux automount version ([\w.]+)}.match(autofs_version)[1]
  end
end
