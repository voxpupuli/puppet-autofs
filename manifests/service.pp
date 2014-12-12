# Service Documentation.

class autofs::service {
  service { 'autofs' :
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
  }
}
