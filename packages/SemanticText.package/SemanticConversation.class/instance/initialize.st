initialize-release
initialize

	super initialize.
	
	model := self defaultModel.
	messages := OrderedCollection new.
	toolSpecs := IdentityDictionary new.