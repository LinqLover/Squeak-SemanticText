service
countTokensIn: aString

	self flag: #approximation. "Upper approximation! Could use something like OpenAI's tiktoken for more precise counts."
	
	^ self maxTokensInStringOfSize: aString size