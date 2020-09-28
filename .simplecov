# frozen_string_literal: true

SimpleCov.start do
  root ENV["ENGINE_ROOT"]

  add_filter "lib/decidim/term_customizer/version.rb"
  add_filter "/spec"

  add_group "Controllers", "app/controllers"
  add_group "Commands", "app/commands"
  add_group "Forms", "app/forms"
  add_group "Services", "app/services"
  add_group "Decidim Extensions", "lib/extends"
end

SimpleCov.command_name ENV["COMMAND_NAME"] || File.basename(Dir.pwd)

SimpleCov.merge_timeout 1800
