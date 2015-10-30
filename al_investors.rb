require 'net/http'
require 'json'
require 'csv'

###############################

list_of_urls = %Q(
LIST OF COMPANIES HERE 
)

access_token = "YOUR ACCESS TOKEN HERE"

###############################

array_of_urls = list_of_urls.split(/\n/)
array_of_urls.reject! {|a| a.empty? }

def get_request(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  begin
    res = Net::HTTP.get_response(uri)
    return JSON.parse(res.body)
  rescue
    puts "Could not make request to #{url} with #{params}"
    if res && res.body
      puts "Response was: #{res.body}"
    end
    return false
  end
end

def get_al_details(url, access_token)
  startup_roles = nil
  id = nil

  slug = url.split(".co/")[1]
  params = { :type => 'Startup', :query => slug, :access_token => access_token}
  request_url = "https://api.angel.co/1/search"
  startup_results = get_request(request_url, params)
  startup_results.each do |startup_result|
    if startup_result['url']==url
      id = startup_result['id']
    end
  end
  if id 
    params = {:access_token => access_token}
    url = "https://api.angel.co/1/startups/#{id}/roles"
    startup_roles = get_request(url,params)
  end

  return startup_roles
end

csv = CSV.open("investor_names.csv", "wb")
csv << ["name", "website", "angellist url"]

roles_array = Array.new

array_of_urls.each do |url|
  url.strip!
  startup_roles = get_al_details(url, access_token)

  if startup_roles
    startup_roles["startup_roles"].each do |role|
      if role && (role["role"] == "past_investor" || role["role"] == "investor")
        if role["tagged"]
          name = role["tagged"]["name"]
          url = role["tagged"]["company_url"]
          al_url = role["tagged"]["angellist_url"]

          if role["tagged"]["type"] != "User"
            sleep 1
            vc_roles = get_al_details(al_url, access_token)

            if vc_roles && vc_roles["startup_roles"]
              vc_roles["startup_roles"].each do |role|
                if role && (role["role"] == "founder" || role["role"] == "employee")
                  name = role["tagged"]["name"]
                  al_url = role["tagged"]["angellist_url"]

                  unless roles_array.include?(name)
                    roles_array << name
                    csv << [name, url, al_url]
                  end
                end
              end
            end
          end
        end

        unless roles_array.include?(name)
          roles_array << name
          csv << [name, url, al_url]
        end
      end
    end
  end
  sleep rand(5)
end
