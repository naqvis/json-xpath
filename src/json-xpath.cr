# XPath query package for JSON document, lets you extract data from JSON documents through an XPath expression.
module JSONXPath
  VERSION = "0.1.0"

  # Parses the JSON and returns an instance of `JSONXPath::Node`
  def self.parse(input : String | IO)
    Node.parse(input)
  end
end

require "./**"
