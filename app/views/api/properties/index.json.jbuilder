json.array! @properties do |property|
  json.partial! 'api/properties/property', property: property
end