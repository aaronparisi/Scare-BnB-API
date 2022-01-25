json.array! @urls do |url|
  json.partial! 'api/images/url', url: url
end