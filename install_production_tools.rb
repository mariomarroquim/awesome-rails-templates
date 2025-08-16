gem_group :production do
  # Log requests in a single line.
  gem "lograge"
end

# Track changes to models.
gem "paper_trail"

after_bundle do
  run "bundle exec rails g paper_trail:install"

  run "bundle exec rails db:migrate"
end

inject_into_file "config/environments/production.rb", before: "# Settings specified here will take precedence over those in config/application.rb." do
  "# Log requests in a single line.\n  config.lograge.enabled = true\n  config.lograge.custom_payload do |controller|\n    { current_user_id: controller.current_user.try(:id) }\n  end\n\n  "
end

inject_into_file "config/environments/test.rb", after: "Rails.application.configure do" do
  "\n  # Disable tracking changes to models.\n  PaperTrail.enabled = false\n"
end

inject_into_file "app/models/application_record.rb", after: "class ApplicationRecord < ActiveRecord::Base" do
  "\n  # Track all changes to models.\n  has_paper_trail\n"
end

inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base" do
  "\n  # Track who changed models.\n  before_action :set_paper_trail_whodunnit\n"
end
