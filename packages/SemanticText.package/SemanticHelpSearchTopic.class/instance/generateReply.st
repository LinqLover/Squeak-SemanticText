searching
generateReply

	| streamingMessage |
	conversationRequirements := nil.
	SemanticText assureConversationAvailableOr: [:requirements |
		conversationRequirements := requirements.
		^ self triggerUpdateContents].
	
	resultConversation := self corpus
		newConversationForQuery: self term
		systemMessage: 'You are an AI assistant that sits in the interactive help browser of Squeak/Smalltalk.'.
	
	streamingMessage := resultConversation currentStreamingMessage ifNil:
		[^ self triggerUpdateContents].
	
	Project current addDeferredUIMessage: [self updateContents].
	self dependents do: [:dep |
		((dep respondsTo: #currentTopic) and: [dep currentTopic == self]) ifTrue:
			[streamingMessage sendUpdatesFromTextModel: dep selector: #topicContents]].
	streamingMessage when: #completed send: #triggerUpdateContents to: self.
	
	streamingMessage process ifNotNil: [:streamingProcess |
		streamingProcess priority: process priority + 1 "to make stream look fluent"].