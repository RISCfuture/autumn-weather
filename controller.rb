# Controller for the Weather leaf.

class Controller < Autumn::Leaf
  include ActionView::Helpers::DateHelper
  
  WEATHER_USAGE = "Usage: \"!weather 94108\" to get San Francisco weather (zip codes only)."
  METAR_USAGE = "Usage: \"!metar KOAK\" to get Oakland Airport's current METAR (ICAO identifier only)."
  TAF_USAGE = "Usage: \"!taf KOAK\" to get Oakland Airport's current TAF (ICAO identifier only)."
  
  # Typing "!about" returns information about this leaf.
  
  def about_command(stem, sender, reply_to, msg)
  end
  
  # Typing "!weather 94108" returns the weather for San Francisco, in textual
  # format.
  
  def weather_command(stem, sender, reply_to, msg)
    return WEATHER_USAGE if msg.nil?
    weather_xml = open("http://weather.yahooapis.com/forecastrss?p=#{URI.escape msg}")
    weather = Hpricot(weather_xml)
    title = (weather/'channel/title').inner_text.match(/^Yahoo! Weather - (.+)$/)[1]
    return WEATHER_USAGE if title == 'Error'
    
    var :valid_time => Time.parse((weather/'lastbuilddate').inner_text)
    var :city => (weather/'yweather:location').first['city']
    var :state => (weather/'yweather:location').first['region']
    var :units_temp => ('°' + (weather/'yweather:units').first['temperature'])
    var :wind_speed => (weather/'yweather:wind').first['speed'].to_i
    var :temperature => (weather/'yweather:condition').first['temp'].to_i
    var :condition => (weather/'yweather:condition').first['text']
  end
  
  # Typing "!metar KOAK" returns the weather for Oakland Airport, in METAR
  # format.
  
  def metar_command(stem, sender, reply_to, msg)
    return METAR_USAGE if msg.nil?
    html = open("http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc=#{URI.escape msg}")
    page = Hpricot(html)
    metar_elements = (page/"font[@face='courier']")
    if metar_elements.empty? then
      return "Airport #{msg} not found. Is it in ICAO format?"
    else
      return metar_elements.first.inner_text.gsub(/\n/, '')
    end
  end
  
  # Typing "!taf KOAK" returns the forecast for Oakland Airport, in TAF format.
  
  def taf_command(stem, sender, reply_to, msg)
    return TAF_USAGE if msg.nil?
    html = open("http://weather.noaa.gov/cgi-bin/mgettaf.pl?cccc=#{URI.escape msg}")
    page = Hpricot(html)
    taf_elements = (page/"pre")
    if taf_elements.empty? then
      return "Airport #{msg} not found. Is it in ICAO format?"
    else
      taf = taf_elements.first.inner_text.chomp
      taf_lines = taf.split(/\n/)
      taf_lines.shift
      taf_lines.map!(&:strip)
      return taf_lines.join("\n")
    end
  end
end
