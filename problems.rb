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
			pkgs = NixOS::find_homepage(package["homepage"])

			attr_names = pkgs.map { |attr, pkg| attr }.join(", ")
			# FIXME : This does not map to an attribute name, nor to a nixos file.
			main_line = [
				" * [ ]",
				package["name"],
				# Not great
				#(attr_names and attr_names.length > 0) ? "`#{attr_names}`" : "",
				package["homepage"] ? "(#{package["homepage"]})" : "",
				package["new_homepage"] ? " → (#{package["new_homepage"]})" : "",
			].join(" ")
			sub_line = ""
			
			# Not great either
			#if pkgs and pkgs.length > 0 then
			#	sub_line = "\n" + 
			#		pkgs.map do |attr, pkg|
			#			position = pkg["meta"]["position"]
			#			if position then
			#				file = position.split(":").first
			#				line = position.split(":").last
			#				link = "https://github.com/NixOS/nixpkgs/blob/#{NixOS::COMMIT}/#{file}#L#{line}"
			#				link = "[#{position}](#{link})"
			#				"     * " + link
			#			end
			#		end
			#		.uniq
			#		.join("\n")
			#end
			main_line + sub_line
		end.join("\n")

	puts <<~EOF
	## Problem: #{problem}

	#{list}

	* * *

	EOF
end
