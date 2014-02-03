class Segregate
	REQUEST_LINE = /^(#{HTTP_METHODS.join("|")})\s(\*|\S+)\sHTTP\/(\d).(\d)$/
	STATUS_LINE = /^HTTP\/(\d).(\d)\s(\d{3})\s([\w\s\-]+)$/
	UNKNOWN_REQUEST_LINE = /^(\w+)\s(\*|\S+)\sHTTP\/(\d).(\d)$/
end