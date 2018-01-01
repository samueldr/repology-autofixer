
def repo_cmd(*cmd)
	Dir.chdir(REPO_LOCATION) do
		system(*cmd)
	end
end

def git(*cmd)
	repo_cmd("git", *cmd)
end
