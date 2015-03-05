Gem::Specification.new do |s|

	s.name        = 'slothbot'
	s.version     = '0.1.0'
	s.summary     = "A very lazy IRC bot for very lazy people."
	s.authors     = ['sleeper']
	s.email       = ['sleeper@slothkrew.com']
	s.homepage    = 'https://github.com/Slothkrew/Slothbot'
	s.license     = 'MIT'
	
	s.files       = Dir['lib/**/*.rb']
	s.bindir      = 'bin'
	s.executables << 'slothbot'
	s.executables << 'wheel'

	s.add_runtime_dependency 'cinch', '2.2.3'
	s.add_runtime_dependency 'sqlite3', '1.3.10'

end
