json.title property.title
json.description property.description
json.beds property.beds
json.baths property.baths
json.nightly_rate property.nightly_rate
json.pets property.pets
json.smoking property.smoking
json.square_feet property.square_feet

json.address do
  json.partial! 'api/addresses/address', address: property.address
end

json.manager do
  json.partial! 'api/users/manager', manager: property.manager
end