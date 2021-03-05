json.property do
  json.partial! 'api/properties/property', property: booking.property
end
json.startDate booking.start_date
json.endDate booking.end_date