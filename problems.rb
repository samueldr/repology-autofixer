#!/usr/bin/env nix-shell
#!ruby
#!nix-shell -p git -p ruby -i ruby

require File.join(__dir__(), "lib/repology.rb")
require File.join(__dir__(), "lib/nixos.rb")

# Get a list of problems.
$problems = Repology::problems()

$problems.keys.sort.each do |key|
	problems = $problems[key]
	type = problems.first["base_type"]
	problem = "Unknown problems"
	case type
	when :homepage_gone
		problem = "Home page gone with status: #{problems.first["status"]}"
	when :hoster_gone
		problem = "Hoster gone (#{problems.first["hoster"]})"
	when :permanent_redirect
		problem = "Homepage link is a permanent redirect."
	end

	list = problems
		.uniq { |p| p["name"] }
		.sort { |a, b| a["name"].downcase <=> b["name"].downcase }
		.map do |package|
		# FIXME : This does not map to an attribute name, nor to a nixos file.
		[
			" *",
			package["name"],
			package["homepage"] ? "(#{package["homepage"]})" : "",
			package["new_homepage"] ? " → (#{package["new_homepage"]})" : "",
		].join(" ")
	end.join("\n")

	puts <<~EOF
	## Problem: #{problem}

	#{list}

	* * *

	EOF
end
