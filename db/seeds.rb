# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Booking.destroy_all
Address.destroy_all
Property.destroy_all
User.destroy_all

locations = []
characters = []

numLocations = 10

until locations.length == numLocations do
  locations.push Faker::TvShows::Simpsons.location
  locations = locations.uniq
end

until characters.length == numLocations * 2 do
  characters.push Faker::TvShows::Simpsons.character.split(' ').join('_')
  characters = characters.uniq
end

# first 10 characters are managers aka hosts
for i in (0...numLocations-1) do
  managerName = characters[i]
  locationName = locations[i]

  aManager = User.create(username: managerName, email: "#{managerName}@springfieldbnb.com", password: 'password', image_url: managerName)

  aProperty = Property.create(beds: rand(1...5), baths: rand(1...4), pets: true, smoking: false, square_feet: rand(5000), nightly_rate: rand(25...5000), description: Faker::TvShows::Simpsons.quote, title: locationName, manager_id: aManager.id)
  anAddress = Address.create(line_1: Faker::Address.street_address, line_2: Faker::Address.secondary_address, city: 'Springfield', state: 'North Takoma', zip: 192005, property_id: aProperty.id)
end

for i in (0...numLocations-1) do
  guestName = characters[i+numLocations]
  aGuest = User.create(username: guestName, email: "#{guestName}@springfieldbnb.com", password: 'password', image_url: guestName)

  startDate1 = Date.today + 7
  endDate1 = startDate1 + 3
  propId1 = i % (numLocations-1) + 1
  booking1 = Booking.create(start_date: startDate1, end_date: endDate1, guest_id: aGuest.id, property_id: propId1)

  startDate2 = Date.today + 14
  endDate2 = startDate2 + 3
  propId2 = (i+1) % (numLocations-1) + 1
  booking2 = Booking.create(start_date: startDate2, end_date: endDate2, guest_id: aGuest.id, property_id: propId2)
end