require 'pp'
require 'json'


k = JSON open('../meta/khan.json').read()
@videos = {}
k.each { |playlist| playlist['videos'].each {|video| @videos[video['title']] = video }}

Dir.glob("../srt/**/*").each do |item|
  next if item == '.' or item == '..'
  unless File.directory?(item)
    @title = item.gsub(/[^\/]*\/|\.en\.srt/, "").gsub(/_+/, " ")
    puts item
    if @videos[@title]
      File.rename item, "../srt/khan/bio/#{@videos[@title]['youtube_id']}.srt"
      puts @videos[@title]['youtube_id']
    else
      puts @title
    end
  end
end