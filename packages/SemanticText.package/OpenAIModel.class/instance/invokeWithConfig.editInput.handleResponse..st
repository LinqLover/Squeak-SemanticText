private
invokeWithConfig: aConfigOrNil editInput: inputBlock handleResponse: responseBlock

	| config input output response |
	config := self baseConfig.
	aConfigOrNil ifNotNil:
		[config := config updatedWith: aConfigOrNil].
	
	input := JsonObject new
		model: self name;
		yourself.
	inputBlock ifNotNil:
		[inputBlock cull: input cull: config].
	
	response := WebClient new
		httpPost: self url
		content: input asJsonString squeakToUtf8
		type: 'application/json'
		do: [:request |
			request headerAt: 'Authorization' put: 'Bearer ' , self account apiKey].
	
	output := (responseBlock ifNotNil: [responseBlock cull: response cull: config])
		ifNil: [response content utf8ToSqueak parseAsJson].
	
	response isSuccess ifFalse:
		[| error |
		error := output at: #error.
		^ OpenAIError
			signalForType: error type
			parameter: error param
			code: error code
			message: error message].
	
	output usage ifNotNil: [:usage |
		| expense |
		expense := self expenseForUsage: usage.
		self account noteExpense: expense forUser: config user model: self name].
	
	^ output