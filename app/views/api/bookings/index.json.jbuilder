json.array! @bookings do |booking|
  json.partial! 'api/bookings/booking', booking: booking
end