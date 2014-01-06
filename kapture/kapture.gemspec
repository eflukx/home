# -*- encoding: utf-8 -*-
$:.push File.expand_path("../src", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name        = "kapture"
  s.version     = Kapture::VERSION
  s.authors     = ["Ernst Naezer"]
  s.email       = ["ernstnaezer@gmail.com"]
  s.homepage    = %q{http://github.com/enix/home}
  s.summary     = %q{Datalogger for the @home project}
  s.description = %q{The Data logging @home project has the aim to provide realtime insight in the energie consumption, solar production and the use of other natural resources in the home environment.}
  s.licenses    = ['MIT']

  s.extra_rdoc_files = [
     'LICENSE.txt'
   ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib","plugins"]

end
