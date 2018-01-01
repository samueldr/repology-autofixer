#!/usr/bin/env nix-shell
#!ruby
#!nix-shell -p git -p ruby -i ruby

require "net/http"
require "json"
require "pp"

REPO_LOCATION="#{ENV["HOME"]}/tmp/nixpkgs/nixpkgs"
BRANCH_NAME = "repology/autofixer"

class String
	def word_wrap(text, col_width=80)
		# https://www.ruby-forum.com/topic/57805#46960
		self.gsub( /(\S{#{col_width}})(?=\S)/, '\1 ' )
			.gsub( /(.{1,#{col_width}})(?:\s+|$)/, "\\1\n" )
	end
end

def repo_cmd(*cmd)
	Dir.chdir(REPO_LOCATION) do
		system(*cmd)
	end
end

def git(*cmd)
	repo_cmd("git", *cmd)
end

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

def fix_permanent_redirect(package)
	# Nothing useful to pinpoint where repology got the package from...
	# We'll have to do the hard work!
	#package_infos =
	#	api_get(PACKAGE_URL(package["effname"]))
	#	.select {|p| p["repo"] == NIX_REPO}
	#	.first
	#pp package_infos

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

# Prepare the repo.
git "fetch", "channels"
git "checkout", "nixpkgs-unstable"
git "branch", "-D", BRANCH_NAME
git "pull"
git "reset", "--hard"
git "checkout", "-b", BRANCH_NAME

# Get a list of problems.
permanent_redirects = Repology::permanent_redirects()
permanent_redirects.each do |problem|
	fix_permanent_redirect(problem)
end
