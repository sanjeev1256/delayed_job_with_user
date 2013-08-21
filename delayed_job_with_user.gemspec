Gem::Specification.new do |spec|
  spec.add_dependency 'activesupport', ['>= 3.0', '< 4.1']
  spec.add_dependency 'delayed_job', ['>=4.0']
  
  spec.authors = ["Igor Suleymanoff"]
  spec.description = "Small wrapper around Delayed::Job to instantiate current_user in Job"
  spec.email = ['igorsuleymanoff@gmail.com']
  
  spec.files = %w(README.md delayed_job_with_user.gemspec, init.rb)
  spec.files += Dir.glob('{lib}/**/*')

  spec.homepage = 'http://github.com/radiohead/delayed_job_with_user'
  spec.licenses = ['MIT']
  spec.name = 'delayed_job_with_user'
  spec.require_paths = ['lib']

  spec.summary = "Small wrapper around Delayed::Job to instantiate current_user in Job"
  spec.version = '1.0.0'
end