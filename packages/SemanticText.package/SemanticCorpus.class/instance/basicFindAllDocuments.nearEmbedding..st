search-embeddings
basicFindAllDocuments: number nearEmbedding: embedding
	"Note: Ranking of results is invariant of length of the embedding argument."

	| relatednesses |
	relatednesses := Array new: self documents size streamContents: [:stream |
		self documents do: [:doc |
			| distance |
			distance := self distanceBetween: embedding and: doc embedding.
			(distance isInfinite or: [distance isNaN]) ifFalse: [
				stream nextPut: doc -> distance]]].
	self flag: #optimize. "use flat array instead of associations and write custom sort method. 56% of runtime comes from #->."
	
	relatednesses sort: [:assoc1 :assoc2 | assoc1 value <= assoc2 value]. "faster than sort function"
	^ relatednesses take: number