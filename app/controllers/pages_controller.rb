class PagesController < ApplicationController
  def index; end

  def login
    redirect_to action: 'index' and return if params[:name].blank? || params[:password].blank?

    password_hash = Digest::MD5.hexdigest(params[:password].to_s)
    session_key = SecureRandom.hex(16)
    character = Character.find_by(name: params[:name])
    redirect_to action: 'index' and return if character.present? && character.password != password_hash

    character = Character.create(name: params[:name], password: password_hash) if character.blank?
    character.update(session: session_key)
    cookies[:session_key] = {
      value: session_key,
      expires: 1.day.from_now
    }

    redirect_to action: 'game'
  end

  def logout
    @character = Character.find_by(session: cookies[:session_key])
    @character.update(session: nil) if @character.present?
    cookies.delete(:session_key)
    redirect_to action: 'index'
  end

  def game
    @character = Character.find_by(session: cookies[:session_key])

    if @character.blank?
      cookies.delete(:session_key)
      redirect_to action: 'index' and return
    end
    join_event = Event.character_join(@character)
    @events = [join_event]
  end

  def receive_command
    @character = Character.find_by(session: cookies[:session_key])
    return unless @character.present?

    Event.handle_command(@character, params[:command])
  end
end
