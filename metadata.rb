name             'druid'
maintainer       'N3TWORK'
maintainer_email 'yuval@n3twork.com'
license          'Apache 2.0'
description      'Installs/Configures druid'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.3'

depends 'java'
depends 'git'
depends 'supervisor', '~> 0.4.12'