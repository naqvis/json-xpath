# JSON XPath
[![Build Status](https://travis-ci.org/naqvis/json-xpath.svg?branch=master)](https://travis-ci.org/naqvis/json-xpath)
[![GitHub release](https://img.shields.io/github/release/naqvis/json-xpath.svg)](https://github.com/naqvis/json-xpath/releases)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://naqvis.github.io/json-xpath/)

JSON XPath shard provides XPath query functionality for JSON document, it lets you extract data from JSON documents through an XPath expression.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     json-xpath:
       github: naqvis/json-xpath
   ```

2. Run `shards install`

## Usage

```crystal
require "json-xpath"

json = <<-JSON
{
 "store": {
     "book": [
         {
             "category": "reference",
             "author": "Nigel Rees",
             "title": "Sayings of the Century",
             "price": 8.95
         },
         {
             "category": "fiction",
             "author": "Evelyn Waugh",
             "title": "Sword of Honour",
             "price": 12.99
         },
         {
             "category": "fiction",
             "author": "Herman Melville",
             "title": "Moby Dick",
             "isbn": "0-553-21311-3",
             "price": 8.99
         },
         {
             "category": "fiction",
             "author": "J. R. R. Tolkien",
             "title": "The Lord of the Rings",
             "isbn": "0-395-19395-8",
             "price": 22.99
         }
     ],
     "bicycle": {
         "color": "red",
         "price": 19.95
     }
 }
}
JSON

books = JSONXPath.parse(json)

# Find authors of all books in the store
list = books.xpath_nodes("store/book/*/author")
# OR
# list = books.xpath_nodes("//author")

list.each { |a| puts a.content }
# => Nigel Rees
# => Evelyn Waugh
# => Herman Melville
# => J. R. R. Tolkien

# Find the Third book
book = books.xpath("//book/*[3]")
book.try &.children.each { |a| puts "#{a.data} : #{a.content}" }

# => author : Herman Melville
# => category : fiction
# => isbn : 0-553-21311-3
# => price : 8.99
# => title : Moby Dick

# Find the last book
book = books.xpath("//book/*[last()]")
book.try &.children.each { |a| puts "#{a.data} : #{a.content}" }

# =>  author : J. R. R. Tolkien
# =>  category : fiction
# =>  isbn : 0-395-19395-8
# =>  price : 22.99
# =>  title : The Lord of the Rings

# OR call `raw` property to retrive raw JSON
pp book.try &.raw

# => {"category" => "fiction",
# "author" => "J. R. R. Tolkien",
# "title" => "The Lord of the Rings",
# "isbn" => "0-395-19395-8",
#"price" => 22.99}

# Find all books with isbn number
list = books.xpath_nodes("//book/*[isbn]")
puts list.size # => 2

# Find all books cheaper than 10
list = books.xpath_nodes("//book/*[price<10]")
puts list.size # => 2

# Sum the price of all books
price = books.xpath_float("sum(//book/*/price)")
puts price # => 53.92
```

refer to `spec` for usage examples. And refer to [Crystal XPath2 Shard](https://github.com/naqvis/crystal-xpath2) for details of what functions and functionality is supported by XPath implementation.

## Development

To run all tests:

```
crystal spec
```

## Contributing

1. Fork it (<https://github.com/naqvis/json-xpath/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer
