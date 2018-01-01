#!/usr/bin/env nix-shell
#!ruby
#!nix-shell -p git -p ruby -i ruby

require File.join(__dir__(), "lib/repology.rb")
require File.join(__dir__(), "lib/nixos.rb")
require File.join(__dir__(), "lib/utils.rb")
require File.join(__dir__(), "lib/string.rb")

REPO_LOCATION="#{ENV["HOME"]}/tmp/nixpkgs/nixpkgs"
BRANCH_NAME = "repology/autofixer"

# Prepare the repo.
git "fetch", "channels"
git "checkout", "nixpkgs-unstable"
git "branch", "-D", BRANCH_NAME
git "pull"
git "reset", "--hard"
git "checkout", "-b", BRANCH_NAME

# Get a list of problems.
permanent_redirects = Repology::permanent_redirects()
permanent_redirects.each do |package|
	puts "---"
	puts "ACTION: fix_permanent_redirect"
	puts "PACKAGE: repology: #{package["name"]}"
	puts "PROBLEM: #{package["problem"]}"

	package["problem"].match(Repology::PERMANENT_REDIRECT_REGEX)
	pkgs = NixOS::find_homepage($1)

	puts ""
	puts "nixpkgs packages affected: #{pkgs.map{|attr, pkg| attr}.join(", ")}"
	pkgs.each do |attr, pkg|
		file = pkg["meta"]["position"]
		# It can happen, somehow, that a package won't have a position attribute.
		# For those, we'll have to rely on a manual fix!
		next unless file
		file = file.split(":").first
		# hmmm... that's not elegant.
		repo_cmd "sed", "-i", "-e", "s;#{$1};#{$2};g", file

		# Do the git dance.
		git "add", file
		msg = <<~EOF
			#{attr}: Updates homepage URL.
			
			This commit automatically fixes the following problem:

			> #{package["problem"].word_wrap(70).split("\n").join("\n> ")}

			(Commit automatically made using repology-autofixer)
		EOF
		git "commit", "-m", msg
	end

	puts ""
end
