require "json"

module NixOS
	tmp = JSON.parse(File.read("./packages-unstable.json"))
	PACKAGES = tmp["packages"]
	COMMIT   = tmp["commit"]

	def self.find_homepage(homepage)
		PACKAGES.select do |k, pkg|
			pkg["meta"]["homepage"] == homepage
		end
	end
end
