# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'date'
require 'securerandom'

User.create(email: "test@example.com", password: "12345678")


# fb
FbDb.destroy_all

today = Date.today - 1 

366.times do |i|
  date = today.strftime('%Y-%m-%d')
  FbDb.create(
    date: date,
    fans: rand(100000...1000000),
    fans_adds_day: rand(1...100),
    fans_losts_day: rand(1...10),
    page_users_day: rand(1000...10000),
    posts_users_day: rand(1000...10000),
    fans_adds_week: rand(10...1000),
    fans_losts_week: rand(10...100),
    page_users_week: rand(10000...100000),
    posts_users_week: rand(10000...100000),
    fans_adds_month: rand(100...10000),
    fans_losts_month: rand(100...10000),
    page_users_month: rand(100000...10000000),
    posts_users_month: rand(100000...10000000),
    post_enagements_day: rand(10...100),
    negative_users_day: rand(1...100),
    post_enagements_week: rand(100...1000),
    negative_users_week: rand(10...1000),
    post_enagements_month: rand(1000...10000),
    negative_users_month: rand(100...10000),
    link_clicks_day: rand(1...10),
    link_clicks_week: rand(10...100),
    link_clicks_month: rand(100...1000),
    fans_female_day: rand(100...10000),
    fans_male_day: rand(100...10000),
    fans_13_17: rand(10...1000),
    fans_18_24: rand(10...1000),
    fans_25_34: rand(10...1000),
    fans_35_44: rand(10...1000),
    fans_45_54: rand(10...1000),
    fans_55_64: rand(10...1000),
    fans_65: rand(10...1000),
    enagements_users_day: rand(10...1000),
    enagements_users_week: rand(10...1000),
    enagements_users_month: rand(10...1000),
  )
  today = today - 1
end

puts "create #{FbDb.count} fb data"



# ga

GaDb.destroy_all

today = Date.today - 1

366.times do |i|
  date = today.strftime('%Y-%m-%d')
  GaDb.create(
    date: date,
    web_users_day: rand(1...100),
    web_users_week: rand(100...1000),
    web_users_month: rand(1000...10000),
    session_pageviews_day: rand(1...100),
    sessions_day: rand(1...100),
    bouce_rate_day: rand(0.01...1),
    pageviews_day: rand(1000...10000),
    avg_session_duration_day: rand(1...100),
    avg_time_on_page_day: rand(1...100),
    pageviews_per_session_day: rand(1...100),
    desktop_user: rand(1...1000),
    mobile_user: rand(1...1000),
    tablet_user: rand(1...1000),
    female_user: rand(1...10000),
    male_user: rand(1...10000),
    user_18_24: rand(1...1000),
    user_25_34: rand(1...1000),
    user_35_44: rand(1...1000),
    user_45_54: rand(1...1000),
    user_55_64: rand(1...1000),
    user_65: rand(1...1000),
    referral_user_day: rand(1...1000),
    direct_user_day: rand(1...1000),
    social_user_day: rand(1...1000),
    email_user_day: rand(1...1000),
    oganic_search_day: rand(1...1000),
    direct_bounce: rand(0.01...1),
    email_bounce: rand(0.01...1),
    social_bounce: rand(0.01...1),
    oganic_search_bounce: rand(0.01...1),
    referral_bounce: rand(0.01...1),
    new_visitor: rand(1...1000),
    return_visitor: rand(1...1000),
    single_session: rand(100...900),
  )
  today = today - 1
end

puts "create #{GaDb.count} ga data"


# mailchimp
MailchimpDb.destroy_all

today = Date.today - 1

53.times do |i|
  date = today.strftime('%Y-%m-%d')
  MailchimpDb.create(
    date: date, 
    title: SecureRandom.hex,
    email_sent: rand(1...10000),
    open: rand(1...1000),
    open_rate: rand(0.5...1),
    click: rand(1...10000),
    click_rate: rand(0.1...0.5),
    most_click_title: SecureRandom.hex,
    most_click_time: date
  )
  today = today - 7
end

puts "create #{MailchimpDb.count} mailchimp data"




# alexa
AlexaDb.destroy_all

AlexaDb.create(
  sein_rank: rand(1...300),
  newsmarket_rank: rand(1...200),
  pansci_rank: rand(1...90), 
  einfo_rank: rand(1...150),
  npost_rank: rand(1...120),
  womany_rank: rand(1...60),
  sein_bounce_rate: rand(0.01...1),
  newsmarket_bounce_rate: rand(0.01...1),
  pansci_bounce_rate: rand(0.01...1), 
  einfo_bounce_rate: rand(0.01...1),
  npost_bounce_rate: rand(0.01...1),
  womany_bounce_rate: rand(0.01...1),
  sein_pageview: rand(1...1000),
  newsmarket_pageview: rand(1...1000),
  pansci_pageview: rand(1...1000), 
  einfo_pageview: rand(1...1000),
  npost_pageview: rand(1...1000),
  womany_pageview: rand(1...1000),
  sein_on_site: rand(1...10000),
  newsmarket_on_site: rand(1...10000),
  pansci_on_site: rand(1...10000), 
  einfo_on_site: rand(1...10000),
  npost_on_site: rand(1...10000),
  womany_on_site: rand(1...10000)
)

puts "create #{AlexaDb.count} alexa data"

# fb_post

FbPostDb.destroy_all

today = Date.today - 1

366.times do |i|
  date = today.strftime('%Y-%m-%d')
  FbPostDb.create(
    created_time: date,
    message: SecureRandom.hex,
    like: rand(1000...10000),
    comment: rand(10...100),
    share: rand(10...100),
    interact: rand(100...1000),
  )
  today = today - 1
end

puts "create #{FbPostDb.count} fb_post data"