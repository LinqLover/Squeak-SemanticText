accessing
maxTokens
	"The maximum number of tokens in the output, shared between the prompt and completion. Note that models cannot reflect on this parameter - further output will be truncated, and you may need to additionally instruct the model for brevity."

	^ self argumentAt: #maxTokens