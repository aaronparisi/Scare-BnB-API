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

locations = [
  "Simpson_House",
  "Kwik-e-Mart",
  "Springfield_Cemetery",
  "Springfield_Police_Station",
  "Krustyland",
  "Flanders_House",
  "Springfield_Nuclear_Power_Plant",
  "The_First_Church_of_Springfield",
  "Springfield_Elementary_School",
  "Moes_Tavern"
]

characters = [
  "Homer_Simpson",
  "Apu_Nahasapeemapetilon",
  "Maggie_Simpson",
  "Chief_Wiggum",
  "Krusty_the_Clown",
  "Ned_Flanders",
  "Mr_Burns",
  "Reverend_Lovejoy",
  "Edna_Krabappel",
  "Moe_Szyslak",
  "Baby_Gerald",
  "Cletus_Spuckler",
  "Database",
  "Dewey_Largo",
  "Frankie_the_Squealer",
  "Kirk_Van_Houten",
  "Lindsey_Naegle",
  "Poor_Violet",
  "Rod_Flanders",
  "Superintendent_Gary_Chalmers"
]

numLocations = 10

$imagesDir = Rails.root.join('storage', 'BucketSeeders', 'DevSeeder')

def createNewUser(username)
  aUser = User.create(
    username: username,
    email: "#{username}@springfieldbnb.com", 
    password: 'password'
  )

  toOpen = File.join(Rails.root, 'storage', 'BucketSeeders', 'DevSeeder', 'users', username, 'avatar.png')
  aUser.avatar.attach(
    io: File.open(toOpen),
    filename: 'avatar.png',
    content_type: 'image/png'
  )

  aUser.save!  ## not sure if this is necessary...

  return aUser
end

def createNewProperty(locationName, aManager)  ## do I want to pass the entire manager obj?
  aProperty = Property.create(
    beds: rand(1...5), 
    baths: rand(1...4), 
    pets: true, 
    smoking: false, 
    square_feet: rand(5000), 
    nightly_rate: rand(25...5000), 
    description: Faker::TvShows::Simpsons.quote, 
    title: locationName, 
    manager_id: aManager.id
  )

  toIterate = File.join(Rails.root, 'storage', 'BucketSeeders', 'DevSeeder', 'users', aManager.username, 'properties', aProperty.title)
  Dir.foreach(toIterate) do |filename|
    next if filename == '.' or filename == '..'
    
    toOpen = File.join(Rails.root, 'storage', 'BucketSeeders', 'DevSeeder', 'users', aManager.username, 'properties', aProperty.title, filename)
    aProperty.images.attach(
      io: File.open(toOpen), 
      filename: filename, 
      content_type: 'image/png'
    )
  end
  aProperty.save!

  anAddress = Address.create(line_1: Faker::Address.street_address, line_2: Faker::Address.secondary_address, city: 'Springfield', state: 'North Takoma', zip: 192005, property_id: aProperty.id)

  return aProperty
end

def createNewBooking(aGuest, daysInAdvance, propId)
  startDate = DateTime.now.advance({ days: daysInAdvance }).change({ hour: 16 })
  endDate = startDate.advance({ days: 3 })
  aBooking = Booking.create(start_date: startDate, end_date: endDate, guest_id: aGuest.id, property_id: propId)

  return aBooking
end

# empty aws bucket
User.all.each do |user|
  user.avatar.purge
end

Property.all.each do |property|
  property.images.purge
end

# first 10 characters are managers aka hosts
for i in (0..numLocations-1) do
  managerName = characters[i]
  locationName = locations[i]

  aManager = createNewUser(managerName)

  aProperty = createNewProperty(locationName, aManager)
end

## remainder of the guests will have 2 bookings
for i in (0..numLocations-1) do
  guestName = characters[i+numLocations]
  aGuest = createNewUser(guestName)
  propId1 = i % (numLocations) + 1
  propId2 = (i+1) % (numLocations) + 1

  booking1 = createNewBooking(aGuest, 7, propId1)
  booking1 = createNewBooking(aGuest, 14, propId2)
end