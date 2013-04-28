require './json'

Dir['*.json'].each do |file|
  data = File.new(file).read
begin
  puts '---------------------------'
  puts '| Testing: ' + file
  puts '---------------------------'
  puts Ruby.new.apply(JSON.new.parse(data)).inspect
rescue Parslet::ParseFailed => e
  puts e.cause.ascii_tree
end
end