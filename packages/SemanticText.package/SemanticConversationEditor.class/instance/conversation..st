accessing
conversation: aConversation

	conversation := aConversation.
	self changed: #conversation.
	
	self updateStreamingMessage.