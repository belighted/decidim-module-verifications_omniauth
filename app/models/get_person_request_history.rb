class GetPersonRequestHistory
  include Mongoid::Document

  field :person_id, type: Integer
  field :response, type: String
  field :created_at, type: Time, default: -> {Time.now}

end