require "net/http"
require "json"

module Repology
	LINK_REGEX_PART = /([^"]+)/
	QUOTED_LINK_REGEX_PART = /"#{LINK_REGEX_PART}"/

	PERMANENT_REDIRECT_REGEX = /^Homepage link #{QUOTED_LINK_REGEX_PART} is a permanent redirect to #{QUOTED_LINK_REGEX_PART} and should be updated$/

	NIX_REPO = "nix_unstable"

	TYPES = {
		permanent_redirect: PERMANENT_REDIRECT_REGEX,
		homepage_gone:   /^Homepage link #{QUOTED_LINK_REGEX_PART} is dead \(([^)]+)\) for more than a month.$/,
		hoster_gone:     /^Homepage link #{QUOTED_LINK_REGEX_PART} points to (.*?) which was discontinued. The link should be updated \(probably along with download URLs\)./,

		# Makes unknown problem types handled by the same codepath.
		unknown: /.*/,
	}

	# URLs
	REPOLOGY = "https://repology.org";
	PROBLEMS_URL = URI("#{REPOLOGY}/api/v1/repository/#{NIX_REPO}/problems")
	def self.PACKAGE_URL(effname)
		URI("#{REPOLOGY}/api/v1/metapackage/#{effname}")
	end

	def self.api_get(uri)
		JSON.parse(Net::HTTP.get(uri))
	end

	def self.problems()
		api_get(PROBLEMS_URL)
			.map do |desc|
				problem = desc["problem"].strip.gsub(/\n/, " ").gsub(/  /, " ")

				desc["type"] = TYPES.find do |type, regex|
					problem.match(regex)
				end.first
				desc["base_type"] = desc["type"]

				case desc["type"]
				when :permanent_redirect
					desc["homepage"] = $1
					desc["new_homepage"] = $2
				when :homepage_gone
					desc["homepage"] = $1
					desc["status"] = $2
					desc["type"] = (desc["type"].to_s + "_" + (desc["status"]).downcase.gsub(/[^0-9a-z]/, "_")).to_sym
				when :hoster_gone
					desc["homepage"] = $1
					desc["hoster"] = $2
					desc["type"] = (desc["type"].to_s + "_" + (desc["hoster"]).downcase.gsub(/[^0-9a-z]/, "_")).to_sym
				end

				desc
			end
			.group_by do |desc|
				desc["type"]
			end
	end

	def self.permanent_redirects()
		api_get(PROBLEMS_URL)
			.select do |desc|
				desc["problem"].strip.match(PERMANENT_REDIRECT_REGEX)
			end
	end
end

