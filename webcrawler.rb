require 'mechanize'
require 'csv'
require 'sequel'

# Create database and table movies
DB = Sequel.sqlite "database.db"
DB.create_table? :movies do
  primary_key :id
  String :title
  Integer :year
  Float :rating
  String :director
end

movies_db = DB[:movies]
# class for storing movie data
class Movie < Struct.new(:title, :year, :rating, :director); end
movies = []

# access main page and scrape data
agent = Mechanize.new
main_page = agent.get 'http://imdb.com'
list_page = main_page.link_with(text: "Top Rated Movies").click
rows = list_page.root.css(".lister-list tr")

rows.take(10).each do |row|
  title = row.at_css(".titleColumn a").text.strip
  rating = row.at_css(".ratingColumn strong").text.strip

  movie_page = list_page.link_with(text: title).click
  year = movie_page.root.at_css("#titleYear a").text.strip
  director = movie_page.root.at_css("div.credit_summary_item a span").text.strip
  movie = Movie.new(title, year, rating, director)
  movies << movie
end

# Save data to csv file and to database
CSV.open("top10.csv", "w", col_sep: ";") do |csv|
  csv << ["Tytuł", "Rok", "Ocena", "Reżyser"]
  movies.each do |movie|
    csv << [movie.title, movie.year, movie.rating, movie.director]
    movies_db.insert title: movie.title,
    year: movie.year,
    rating: movie.rating,
    director: movie.director
  end
end
