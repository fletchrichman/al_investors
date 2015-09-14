require 'net/http'
require 'json'
require 'csv'

###############################

list_of_urls = %Q(
	PUT YOUR LIST OF ANGELLIST URLS HERE
)

access_token = "PUT YOUR ACCESS TOKEN HERE"

###############################

array_of_urls = list_of_urls.split(/\n/)
array_of_urls.reject! {|a| a.empty? }

def get_request(url, params)
	uri = URI(url)
	uri.query = URI.encode_www_form(params)
	res = Net::HTTP.get_response(uri)
	return res.body if res.is_a?(Net::HTTPSuccess)
end

def get_al_details(url, access_token)
	slug = url.split(".co/")[1]
	params = { :query => slug, :access_token => access_token}
	startup_id = JSON.parse(get_request("https://api.angel.co/1/search/slugs", params))
	id = startup_id["id"]
	params = {:access_token => access_token}
	startup_roles = JSON.parse(get_request("https://api.angel.co/1/startups/#{id}/roles", params))
end



CSV.open("investor_names.csv", "wb") do |csv|

	csv << ["name", "website", "angellist url"]
	roles_array = Array.new

	array_of_urls.each do |url|

		startup_roles = get_al_details(url, access_token)

		startup_roles["startup_roles"].each do |role|
			if role["role"] == "past_investor" || role["role"] == "investor"
				name = role["tagged"]["name"]
				url = role["tagged"]["company_url"]
				al_url = role["tagged"]["angellist_url"]
				if role["tagged"]["type"] != "User"
					vc_roles = get_al_details(al_url, access_token)
					vc_roles["startup_roles"].each do |role| 
						ap "#{role["tagged"]["name"]}, #{role["role"]}, #{url}"
						if role["role"] == "founder" || role["role"] == "employee"
							name = role["tagged"]["name"]
							al_url = role["tagged"]["angellist_url"]
							unless roles_array.include?(name)
								roles_array << name 
								csv << [name, url, al_url]
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

end








