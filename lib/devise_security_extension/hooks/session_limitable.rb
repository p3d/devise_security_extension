# After each sign in, update unique_session_id.
# This is only triggered when the user is explicitly set (with set_user)
# and on authentication. Retrieving the user from session (:fetch) does
# not trigger it.
Warden::Manager.after_set_user :except => :fetch do |record, warden, options|
  if record.respond_to?(:update_unique_session_id!) && warden.authenticated?(options[:scope])
    unique_session_id = Devise.friendly_token
    warden.session(options[:scope])['unique_session_id'] = unique_session_id
    record.update_unique_session_id!(unique_session_id)
  end
end

# Each time a record is fetched from session we check if a new session from another 
# browser was opened for the record or not, based on a unique session identifier. 
# If so, the old account is logged out and redirected to the sign in page on the next request.
Warden::Manager.after_set_user :only => :fetch do |record, warden, options|
  scope = options[:scope]

  if warden.authenticated?(scope)
    unless record.unique_session_id == warden.session(scope)['unique_session_id']
        warden.logout(scope)
        throw :warden, :scope => scope, :message => :session_limited
    end
  end
end