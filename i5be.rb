['rubygems','sinatra','dm-core','dm-validations','dm-aggregates','dm-timestamps'].each {|f| require f}
set :run => false, :reload => true
DataMapper.setup(:default, YAML::load(File.open('database.yml'))[Sinatra::Application.environment])
class Url
  CHARS= "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" unless defined?(CHARS)
  include DataMapper::Resource
  property :id,         Serial
  property :target,     String, :format => :url,    :length => 0..255, :index => true
  property :short,      String, :nullable => false, :length => 0..255, :unique_index => true, :default => ""
  property :created_at, DateTime
  property :updated_at, DateTime
  before :valid? do
    return true if !self.new_record? or (!(self.short.nil?) and self.short.length > 0)
    while (i||=Url.count+1) > 0
      offset = i % CHARS.length
      offset = CHARS.length if offset == 0
      self.short.insert 0, CHARS[offset-1].chr
      i= (i-offset) / CHARS.length
    end
  end
end
get('/:url') { (url = Url.first(:short=>params[:url])) ? redirect(url.target) : status(404) }
get('/')     { haml(:index) }
post '/' do
  target = params["url"]
  target = "http://" + target unless target.index("http://") == 0
  @url = Url.first(:target => target) || Url.create(:target => target)
  haml :index
end
__END__
@@ index
!!! Strict
%html{html_attrs("en")}
  %head
    %meta{"http-equiv"=>"content-type",:content=>"text/html; charset=utf-8"}
    %meta{:name=>"author",:content=>"Belighted + Deaxon"}
    %title i5 | Simple URL shortener
    %script{:type=>"text/javascript"}
      window.onload = function() { document.getElementsByTagName('input')[0].focus() }
    %style{:type=>"text/css",:media=>"screen"}
      body { font:.8em/1.5 "lucida grande", "lucida sans", "luxi sans", "lucida sans unicode", arial, sans-serif; padding:50px; }
      h1 { border-bottom:1px solid #ddd; max-width:500px; margin-bottom:1em; }
      em { font-style:normal; font-weight:400; color:#777; }
      input:first-child { width:200px; margin-right:3px; padding:2px 0; }
      form+p { max-width:480px; font-size:2.5em; letter-spacing:-1px; background:#ffff77; padding:10px; }
  %body
    %h1== i5 | <em>Simple URL shortener</em>
    %form{:action=>"/",:method=>"post"}
      %p
        %input{:name=>"url", :title=>"URL to compress"}
        %input{:type=>"submit", :value=>"Compress"}
    - if @url
      %p= @url.valid? ? "http://i5.be/#{@url.short}" : "Could not save your URL"