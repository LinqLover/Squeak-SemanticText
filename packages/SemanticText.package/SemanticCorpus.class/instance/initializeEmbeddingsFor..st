embeddings
initializeEmbeddingsFor: someDocuments

	| requestsPerMinute model tokensPerRequest stringsPerRequest iterator |
	"Update documents in chunks to minimize model overhead. Honor rate limits."
	self flag: #magicNumbers. "We currently rely on the rate limits of the model to maximize embedded documents per time. We currently do not include any safety buffer since token approximations are rounded up. Some providers also indicate rate limits in headers (https://platform.openai.com/docs/guides/rate-limits/rate-limits-in-headers) which could possibly be relevant for us. See also: https://github.com/openai/openai-cookbook/blob/a74a7a7940928d504f6e9f7300ddef7f47e8659d/examples/api_request_parallel_processor.py"
	requestsPerMinute := 1 minute // 4 seconds. "for smoother progress updates"
	
	model := self embeddingModel.
	(model respondsTo: #requestsPerMinute) ifTrue:
		[model requestsPerMinute ifNotNil: [:modelRequestsPerMinute |
			requestsPerMinute := requestsPerMinute clampHigh: modelRequestsPerMinute]].
	tokensPerRequest := ((model respondsTo: #tokensPerMinute)
		ifTrue: [model tokensPerMinute])
			ifNotNil: [:tokensPerMinute | tokensPerMinute / requestsPerMinute]
			ifNil: [Float infinity].
	stringsPerRequest := ((model respondsTo: #maxStringsPerRequest)
		ifTrue: [model maxStringsPerRequest])
			ifNil: [Float infinity].
	
	"show progress bar for more than 1 new documents"
	iterator := someDocuments size > 1
		ifTrue: [[:block | (((model respondsTo: #pricePerMinute) ifTrue: [model pricePerMinute])
			ifNotNil: [:pricePerMinute | 'Initializing embeddings (approx {1} per minute)...' format: {pricePerMinute}]
			ifNil: ['Initializing embeddings...']) semanticDisplayRichProgressFrom: 0 to: someDocuments size during: block]]
		ifFalse: [[:block | block value: [:position |]]].
	
	iterator value: [:bar |
		| nextRequest |
		nextRequest := DateAndTime now.
		someDocuments asArray readStream in: [:fullStream |
			[fullStream atEnd] whileFalse: [
				| chunk chunkTexts chunkTokens nextDocument nextText nextDocumentTokens embeddings |
				chunk := OrderedCollection new.
				chunkTexts := OrderedCollection new.
				chunkTokens := 0.
				[(nextDocument := fullStream peek) notNil and:
					[nextText := fullStream peek text.
					chunk size < stringsPerRequest
						and:
							[nextDocumentTokens := model countTokensIn: nextText.
							(chunkTokens + nextDocumentTokens <= tokensPerRequest)
								or:
									[chunk isEmpty and:
										[self notify: 'skipping too large document'.
										fullStream next.
										true "continue"]]]]]
						whileTrue:
							[chunk addLast: fullStream next.
							chunkTexts addLast: nextText.
							chunkTokens := chunkTokens + nextDocumentTokens].
				
				((nextRequest - DateAndTime now) clampLow: 0 seconds) wait.
				nextRequest := requestsPerMinute reciprocal minutes fromNow.
				embeddings := model getEmbeddingsForAll: chunkTexts config: self embeddingConfig.
				
				chunk with: embeddings do: [:doc :embedding |
					doc embedding: embedding].
				
				bar value: fullStream position]]].