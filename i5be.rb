%w(rubygems sinatra dm-core dm-validations dm-aggregates dm-timestamps uri).each {|f| require f}
set :reload => true
DataMapper.setup(:default, YAML::load(File.open('database.yml'))[Sinatra::Application.environment])
class Url
  CHARS= "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" unless defined?(CHARS)
  include DataMapper::Resource
  property :id,         Serial
  property :target,     String, :format => :url, :length => 0..255, :index => true
  property :short,      String, :default => ""
  property :created_at, DateTime
  def self.create_url(params)
    url = Url.new params
    while (i||=Url.count+1) > 0
      offset = ((i % CHARS.length) == 0 ? CHARS.length : (i % CHARS.length))
      url.short.insert 0, CHARS[offset-1].chr
      i= (i-offset) / CHARS.length
    end
    url.save && url
  end
end
saveurl = Proc.new do
  target = URI::parse(params[:url] || request.fullpath[1..-1]).to_s
  target = "http://" + target unless target.index("http://") == 0
  @url = Url.first(:target => target) || Url.create_url(:target => target)
  haml :index
end
post('/',&saveurl)
get(%r{/http:\/\/.+},&saveurl)
get('/:url') { (url = Url.first(:short=>params[:url])) ? redirect(url.target) : status(404) }
get('/')     { haml(:index) }
__END__
@@ index
!!! Strict
%html{html_attrs("en")}
  %head
    %meta{"http-equiv"=>"content-type",:content=>"text/html; charset=utf-8"}
    %meta{:name=>"author",:content=>"Belighted + Deaxon"}
    %title i5 | Simple URL shortener
    %script{:type=>"text/javascript"}
      window.onload = function() {document.getElementsByTagName('input')[0].focus()}
    %style{:type=>"text/css",:media=>"screen"}
      body {font:.8em/1.5 "lucida grande", "lucida sans", "luxi sans", "lucida sans unicode", arial, sans-serif; margin:0; padding:0}
      body>p:first-child {font-size:.85em; padding:.7em 50px .3em; background:#eee; border-bottom:1px solid #ddd; margin:0 0 5em}
      body>p:first-child~* {margin-left:50px}
      a {text-decoration:none}
      h1 {border-bottom:1px solid #ddd; max-width:500px; margin-bottom:1em}
      em {font-style:normal; font-weight:400; color:#777}
      input:first-child {width:200px; margin-right:3px; padding:2px 0}
      form+p {max-width:480px; font-size:2.5em; letter-spacing:-1px; background:#ffff77; padding:10px}
  %body
    %p Use the <a href='javascript:location="http://i5.be/"+location'>Shorten</a> bookmarklet!
    %h1 i5 | <em>Simple URL shortener</em>
    %form{:action=>"/",:method=>"post"}
      %p
        %input{:name=>"url", :title=>"URL to shorten"}
        %input{:type=>"submit", :value=>"Shorten"}
    - if @url
      %p= @url.valid? ? "http://i5.be/#{@url.short}" : "Could not save your URL"