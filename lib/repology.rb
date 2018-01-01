require "net/http"
require "json"

BRANCH_NAME = "repology/autofixer"

module Repology
	PERMANENT_REDIRECT_REGEX = /Homepage link "([^"]+)" is a permanent redirect to "([^"]+)" and should be updated/

	NIX_REPO = "nix_unstable"

	# URLs
	REPOLOGY = "https://repology.org";
	PROBLEMS_URL = URI("#{REPOLOGY}/api/v1/repository/#{NIX_REPO}/problems")
	def self.PACKAGE_URL(effname)
		URI("#{REPOLOGY}/api/v1/metapackage/#{effname}")
	end

	def self.api_get(uri)
		JSON.parse(Net::HTTP.get(uri))
	end

	def self.permanent_redirects()
		api_get(PROBLEMS_URL)
			.select do |desc|
				desc["problem"].strip.match(PERMANENT_REDIRECT_REGEX)
			end
	end
end

