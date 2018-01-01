class String
	def word_wrap(text, col_width=80)
		# https://www.ruby-forum.com/topic/57805#46960
		self.gsub( /(\S{#{col_width}})(?=\S)/, '\1 ' )
			.gsub( /(.{1,#{col_width}})(?:\s+|$)/, "\\1\n" )
	end
end
