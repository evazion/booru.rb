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

  s.add_development_dependency "rake", "~> 11.3"

  s.add_runtime_dependency "faraday", "~> 0.9"
  s.add_runtime_dependency "json", "~> 2.0"
  s.add_runtime_dependency "net-http-persistent", "~> 2.9"
  s.add_runtime_dependency "pry", "~> 0.10"
  s.add_runtime_dependency "thor", "~> 0.19"
end
