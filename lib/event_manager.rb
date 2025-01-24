require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_numbers(number)
  number = number.gsub(/[()-.  ]/, '')
  if number.length == 10
    number
  elsif number.length == 11 && number[0] == 1
    number[1..-1]
  else
    nil
  end
end

def get_hour(date_time)
  Time.parse(date_time.split(' ')[1]).hour
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_times = {}
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_phone_numbers(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  hour = get_hour(row[:regdate])

  reg_times[hour] ? reg_times[hour] += 1 : reg_times[hour] = 1
 # form_letter = erb_template.result(binding)

 # save_thank_you_letter(id,form_letter)
end

p reg_times