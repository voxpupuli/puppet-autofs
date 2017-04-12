Facter.add(:autofs_version) do
  confine :kernel => 'Linux'
  setcode do
    if Facter::Util::Resolution.which('automount')
      autofs_version_command = 'automount -V 2>&1'
      autofs_version = Facter::Util::Resolution.exec(autofs_version_command)
      %r{Linux automount version ([\w\.]+)}.match(autofs_version)[1]
    end
  end
end
