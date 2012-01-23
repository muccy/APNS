# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{apns}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yasith Fernando", "James Pozdena", "Marco Muccinelli"]
  s.autorequire = %q{apns}
  s.date = %q{2010-03-22}
  s.description = %q{Simple Apple push notification service gem}
  s.email = %q{muccymac@gmail.com}
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README.textile", "Rakefile", "lib/apns", "lib/apns/notification.rb", "lib/apns/mdm_notification.rb", "lib/apns.rb", "lib/apns/apns_error_code_handler.rb", "lib/apns/apns_logger.rb", "lib/apns/config.rb", "lib/apns/feedback.rb", "lib/apns/notification_sender.rb", "lib/apns/connection_provider.rb"]
  s.homepage = %q{http://github.com/thekindofme/apns}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Simple Apple push notification service gem}

  s.add_dependency('awesome_print', '> 0')

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
