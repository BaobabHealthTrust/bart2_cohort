# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_bart2_cohort_session',
  :secret      => '95f5122cda6164c052b06b024f30ace0e05bc74f5b580996f08b0df3d2d0b0269e78bccd985df15c2759a393566fd80de58d866d72687f62c5f8d5fb0bb82f6d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
