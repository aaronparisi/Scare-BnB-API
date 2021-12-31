json.id property.id
json.title property.title
json.description property.description
json.beds property.beds
json.baths property.baths
json.nightly_rate property.nightly_rate
json.pets property.pets
json.smoking property.smoking
json.square_feet property.square_feet
json.manager_id property.manager_id
json.image_urls property.image_urls

if property.address
  json.address do
    json.partial! 'api/addresses/address', address: property.address
  end
end

# json.manager do
#   json.partial! 'api/users/manager', manager: property.manager
# end