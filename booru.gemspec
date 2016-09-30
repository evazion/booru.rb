Gem::Specification.new do |s|
  s.name        = 'booru'
  s.version     = '0.0.1'
  s.date        = '2016-09-22'
  s.summary     = "Danbooru 2 API client"
  s.description = "A simple client for the Danbooru 2 API"
  s.authors     = ["evazion"]
  s.email       = 'noizave@gmail.com'
  s.files       << "lib/booru.rb"
  s.files       << "bin/booru"
  s.files       << "bin/csv2dtext"
  s.executables << "booru"
  s.executables << "csv2dtext"
  s.homepage    = "https://github.com/evazion/booru.rb"
  s.license     = 'MIT'
end
