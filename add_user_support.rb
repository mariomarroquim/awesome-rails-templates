# frozen_string_literal: true

run 'bundle exec rails g authentication'

run 'bundle exec rails db:migrate'

inject_into_file 'db/seeds.rb', after: '#   end' do
  "\n\n  User.create!(email_address: 'admin@example.com', password: 'password', password_confirmation: 'password')\n"
end

run 'bundle exec rails db:seed'

run 'bundle exec rails g controller registrations'

inject_into_file 'app/controllers/registrations_controller.rb', after: 'class RegistrationsController < ApplicationController' do
  <<~RUBY

    allow_unauthenticated_access only: %i[ new create ]

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        start_new_session_for @user
        redirect_to after_authentication_url, notice: "Welcome!"
      else
        flash[:alert] = "Try another email address or password."
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  RUBY
end

file 'app/views/registrations/new.html.erb', <<~CONTENT
  <h1>Sign up</h1>

  <%= tag.div(flash[:alert], style: "color:red") if flash[:alert] %>
  <%= tag.div(flash[:notice], style: "color:green") if flash[:notice] %>

  <%= form_for @user, url: registrations_path do |form| %>
    <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "username", placeholder: "Enter your email address", value: @user.email_address %><br>
    <%= form.password_field :password, required: true, autocomplete: "new-password", placeholder: "Enter new password", maxlength: 72 %><br>
    <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password", placeholder: "Repeat new password", maxlength: 72 %><br>
    <%= form.submit "Sign up" %>
  <% end %>
  <br>

  <%= link_to "Have an account?", new_session_path %>
CONTENT

inject_into_file 'app/views/sessions/new.html.erb', before: '<%= tag.div(flash[:alert], style: "color:red") if flash[:alert] %>' do
  "<h1>Sign in</h1>\n\n"
end

inject_into_file 'app/views/sessions/new.html.erb', after: '<%= link_to "Forgot password?", new_password_path %>' do
  "<br>\n<%= link_to \"Don't have an account?\", new_registration_path %>\n"
end

run 'bundle exec rails g controller users'

inject_into_file 'app/controllers/users_controller.rb', after: 'class UsersController < ApplicationController' do
  <<~RUBY

    before_action :set_user, only: %i[ edit update destroy ]

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to after_authentication_url, notice: "Your account was changed.", status: :see_other
      else
        flash.now[:alert] = "The passwords did not match."
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      terminate_session

      Current.user.destroy!

      redirect_to new_session_url, notice: "Your account was removed."
    end

    private

    def set_user
      @user = Current.user
    end

    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end
  RUBY
end

file 'app/views/users/edit.html.erb', <<~CONTENT
  <h1>Change password</h1>

  <%= tag.div(flash[:alert], style: "color:red") if flash[:alert] %>
  <%= tag.div(flash[:notice], style: "color:green") if flash[:notice] %>

  <%= form_for @user, url: user_path do |form| %>
    <%= form.password_field :password, required: true, autofocus: true, autocomplete: "new-password", placeholder: "Enter new password", maxlength: 72 %><br>
    <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password", placeholder: "Repeat new password", maxlength: 72 %><br>
    <%= form.submit "Save" %>
  <% end %>
  <br>

  <%= link_to "Remove my account", @user, data: { turbo_method: :delete, turbo_confirm: "Are you sure?" }, class: "button" %>
CONTENT

run 'bundle exec rails g controller home'

file 'app/views/home/index.html.erb', <<~CONTENT
  <h1>Home</h1>

  <%= tag.div(flash[:alert], style: "color:red") if flash[:alert] %>
  <%= tag.div(flash[:notice], style: "color:green") if flash[:notice] %>

  <%= link_to "Change password", edit_user_url(Current.user) %><br>
  <%= link_to "Sign out", session_url, data: { turbo_method: :delete } %>
CONTENT

inject_into_file 'config/routes.rb', after: 'resources :passwords, param: :token' do
  "\n  resources :registrations, only: %i[ new create ]\n  resources :users, only: %i[ edit update destroy ]\n  root \"home#index\"\n"
end
