accessing
contentString

	(self content isString or: [self content isText]) ifTrue: [^ self content asString].
	
	^ self content asJsonString