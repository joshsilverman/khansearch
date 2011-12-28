require 'pp'
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
    k.each { |playlist| playlist['videos'].each {|video| @videos[video['youtube_id']] = video }}
    
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

  def initialize(data, youtube_id, videos)
    raise ArgumentError if data.nil? or youtube_id.nil?
    @youtube_id = youtube_id.gsub(/[^\/]*\/|\.srt/, "")
    @title = videos[@youtube_id]['title'] if videos[@youtube_id]
    
    @sections = []
    data.split(/^\r\n/).each_with_index do |sd, i|
      psd = parse_section_data(sd) 
      @sections << Section.new(i, self, psd[:id], psd[:timeframe], psd[:text]) if psd
    end
  end

  def search(input)
    results = []
    @sections.each_with_index do |section, i|
      if section.search(input)
        results << [section.text, "http://www.youtube.com/watch?v=#{youtube_id}#at=#{section.timeframe}"] 
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
  attr_accessor :i, :soundtrack, :id, :timeframe, :text, :search

  def initialize(i, soundtrack, id, timeframe, text)
    @i, @soundtrack, @id, @timeframe, @text = i, soundtrack, id, 0, text
    
    t = (timeframe.split(/:|,/).map {|x| x.to_i})
    @timeframe = t[0] * 360 + t[1] * 60 + t[2]
  end

  def search(input)
    terms = input.downcase.split /\s/
    perms = terms.permutation.to_a
    text = @text
    k = @i + 1
    while @soundtrack.sections.length() - 1 >= k
      text += @soundtrack.sections[k].text
      k += 1
      break if k - i == 5
    end
    text = "" if text.nil?
    text.downcase!
    
    #search permutations
    perms.each do |perm|
      return true unless text.match(".+#{perm.join ".+"}.+").nil?
    end
    return false
  end
end

SearchEngine.new