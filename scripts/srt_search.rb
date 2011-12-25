require 'pp'
#require 'yaml'
require 'json'

class SearchEngine
  
  def initialize
    
    c = Compilation.new
    while true
      print "Search Biology Compilation: "
      input = gets.strip
      PP.pp c.search(input)
    end
  end
end

class Compilation
  attr_accessor :search
  
  def initialize
    @soundtracks = []
    
    k = JSON open('../meta/khan.json').read()
    @videos = {}
    k.each { |playlist| playlist['videos'].each {|video| @videos[video['title']] = video }}
    
    Dir.glob("../srt/**/*").each do |item|
      next if item == '.' or item == '..'
      unless File.directory?(item)
        data = open(item).read
        @soundtracks << Soundtrack.new(data, item, @videos)
      end
    end
  end
  
  def search(input)
    results = []
    @soundtracks.each do |soundtrack|
      r = soundtrack.search(input)
      results << [soundtrack.title, r] unless r == []
    end
    results
  end
end

class Soundtrack
  attr_accessor :sections, :title, :search, :youtube_id

  def initialize(data, title, videos)
    raise ArgumentError if data.nil? or title.nil?
    @title = title.gsub(/[^\/]*\/|\.en\.srt/, "").gsub(/_/, " ")
    puts videos.class
    puts videos[@title].class
    @youtube_id = videos[@title]['youtube_id'] if videos[@title]
    puts @title unless videos[@title]
    
    @sections = []
    data.split(/^\r\n/).each do |sd|
      psd = parse_section_data(sd) 
      sections << Section.new(psd[:id], psd[:timeframe], psd[:text]) if psd
    end
  end

  def search(input)
    results = []
    @sections.each_with_index do |section, i|
      if section.search(input)
        results << [section.timeframe, section.text] 
        [0..3]
      end
    end
    results
  end
  
  private

  def parse_section_data(section_data)
    split = section_data.split(/\r\n/, 3)
    return false if split[2].nil?
    {:id => split[0].to_i, :timeframe => split[1], :text => clean_text(split[2])}
  end

  def clean_text(input)
    input.gsub(/\r\n/," ").strip
  end
  
end

class Section
  attr_accessor :id, :timeframe, :text, :search

  def initialize(id, timeframe, text)
    @id, @timeframe, @text = id, 0, text
    
    t = (timeframe.split(/:|,/).map {|x| x.to_i})
    @timeframe = t[0] * 360 + t[1] * 60 + t[2]
  end

  def search(input)
    @text.include?(input)
  end
end

SearchEngine.new