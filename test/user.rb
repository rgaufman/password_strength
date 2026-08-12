# frozen_string_literal: true

class User
  include ActiveModel::Validations

  attr_accessor :username, :password, :login, :email

  def initialize(attributes = {})
    update_attributes(attributes)
  end

  # Assign the attributes and run the validations, so a test can read back
  # either the errors or the record itself.
  def update_attributes(attributes = {})
    attributes.each { |name, value| public_send "#{name}=", value }
    valid?
    self
  end
end
