# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_inkomerce'
  s.version     = '0.1.0'
  s.summary     = 'InKomerce Computer Assisted Negotiation integration with Spree'
  s.description = 'InKomerce CAN (Computer assisted Negotiation) allows stores customers to negotiate for a price. This extenssion allows full integration of InKomerce CAN for Spree stores.'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Ronen Moldovan'
  s.email     = 'ronen@inkomerce.com'
  s.homepage  = 'http://www.inkomerce.com'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'inkomerce-api'

  s.add_dependency 'durable_decorator', '~> 0.2.0'
  s.add_dependency 'spree_api',         '~> 2.1.0'
  s.add_dependency 'spree_backend',     '~> 2.1.0'
  s.add_dependency 'spree_core',        '~> 2.1.0'
  s.add_dependency 'spree_frontend',    '~> 2.1.0'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  
end
