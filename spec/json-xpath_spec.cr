require "./spec_helper"

module JSONXPath
  describe JSONXPath do
    it "Test Parse JSON Number Array" do
      s = "[1,2,3,4,5,6]"
      doc = Node.parse(s)
      doc.children.size.should eq(6)
      v = Array(String).new
      doc.children.each do |n|
        v << n.content
      end
      v.join(",").should eq("1,2,3,4,5,6")
    end

    it "Test Parse JSON Object" do
      s = %({
    		"name":"John",
		    "age":31,
		    "city":"New York"
        })
      doc = Node.parse(s)
      m = Hash(String, String).new
      doc.children.each do |n|
        m[n.data] = n.content
      end

      expected = {
        "name" => "John",
        "age"  => "31",
        "city" => "New York",
      }

      m.should eq(expected)
    end

    it "Test Parse JSON Object Array" do
      s = %([
        { "name":"Ford", "models":[ "Fiesta", "Focus", "Mustang" ] },
        { "name":"BMW", "models":[ "320", "X3", "X5" ] },
            { "name":"Fiat", "models":[ "500", "Panda" ] }
      ])

      doc = Node.parse(s)
      doc.children.size.should eq(3)

      m = Hash(String, Array(String)).new
      doc.children.each do |n|
        name = ""
        models = Array(String).new
        n.children.each do |e|
          if e.data == "name"
            name = e.content
          else
            e.children.each do |k|
              models << k.content
            end
          end
        end
        m[name] = models
      end

      expected = {"Ford" => ["Fiesta", "Focus", "Mustang"],
                  "BMW"  => ["320", "X3", "X5"],
                  "Fiat" => ["500", "Panda"]}

      m.should eq(expected)
    end

    it "Test Parse JSON" do
      s = %({
        "name":"John",
        "age":30,
        "cars": [
          { "name":"Ford", "models":[ "Fiesta", "Focus", "Mustang" ] },
          { "name":"BMW", "models":[ "320", "X3", "X5" ] },
          { "name":"Fiat", "models":[ "500", "Panda" ] }
        ]
      })

      doc = Node.parse(s)
      n = doc.select("name")
      fail "select yields no result" if n.nil?
      n.content.should eq("John")
      fail "next sibling should be nil" unless n.next_sibling.nil?
      cars = n.select("cars")
      cars.try &.children.size.should eq(3)
    end

    it "Test Large Number" do
      s = %({
        "large_number": 365823929453
      })

      doc = Node.parse(s)
      n = doc.select("large_number")
      n.not_nil!.content.should eq("365823929453")
    end

    it "Test JSON Navigator" do
      s = %({
        "name":"John",
        "age":30,
        "cars": [
          { "name":"Ford", "models":[ "Fiesta", "Focus", "Mustang" ] },
          { "name":"BMW", "models":[ "320", "X3", "X5" ] },
          { "name":"Fiat", "models":[ "500", "Panda" ] }
        ]
      })
      doc = parse(s)
      nav = JSONNavigator.new(doc, doc)
      nav.move_to_root
      nav.node_type.should eq(XPath2::NodeType::Root)

      # move to first child(age)
      c = nav.move_to_child
      c.should eq(true)
      "age".should eq(nav.current.data)
      "30".should eq(nav.value)
      # move to next sibling node(cars)
      nav.move_to_next.should eq(true)
      "cars".should eq(nav.current.data)
      m = Hash(String, Array(String)).new

      cur = nav.copy
      ok = nav.move_to_child
      while ok
        # move to <element> node.
        cur1 = nav.copy
        name = ""
        models = Array(String).new
        nok = nav.move_to_child
        while nok
          cur2 = nav.copy
          n = nav.current
          if n.data == "name"
            name = n.content
          else
            ok3 = nav.move_to_child
            while ok3
              cur3 = nav.copy
              models << nav.value
              nav.move_to(cur3)
              ok3 = nav.move_to_next
            end
          end
          nav.move_to(cur2)
          nok = nav.move_to_next
        end
        nav.move_to(cur1)
        m[name] = models
        ok = nav.move_to_next
      end
      expected = {"Ford" => ["Fiesta", "Focus", "Mustang"],
                  "BMW"  => ["320", "X3", "X5"],
                  "Fiat" => ["500", "Panda"]}

      m.should eq(expected)

      nav.move_to(cur)
      # move to name
      nav.move_to_next.should eq(true)
      # move to cars
      nav.move_to_previous
      "cars".should eq(nav.current.data)

      # move to age.
      nav.move_to_first
      "age".should eq(nav.current.data)

      nav.move_to_parent
      nav.current.type.should eq(NodeType::Document)
    end

    it "Test JSON XPath" do
      books = <<-JSON
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

      doc = parse(books)
      expected = ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]

      list = doc.xpath_nodes("store/book/*/author")
      list.map { |n| n.content }.should eq(expected)

      list = doc.xpath_nodes("//author")
      list.map { |n| n.content }.should eq(expected)

      book = doc.xpath("//book/*[3]").not_nil!
      m = Hash(String, String).new
      book.children.each { |a| m[a.data] = a.content }
      expected = {
        "category" => "fiction",
        "author"   => "Herman Melville",
        "title"    => "Moby Dick",
        "isbn"     => "0-553-21311-3",
        "price"    => "8.99",
      }
      m.should eq(expected)

      doc.xpath_float("sum(//book/*/price)").should eq(53.92)

      book = doc.xpath("//book/*[isbn='0-553-21311-3']").not_nil!
      m.clear

      book.children.each { |a| m[a.data] = a.content }
      m.should eq(expected)

      list = doc.xpath_nodes("//book/*[price<10]")
      list.size.should eq(2)
    end
  end
end
