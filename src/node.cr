require "json"

module JSONXPath
  # NodeType is the type of a Node
  enum NodeType : UInt32
    Document = 0
    Element
    Text
  end

  # A Node consists of a `NodeType` and some data (tag name for element nodes, content for text)
  # and are part of a tree of Nodes
  class Node
    property parent : Node?
    property first_child : Node?
    property last_child : Node?
    property prev_sibling : Node?
    property next_sibling : Node?

    getter type : NodeType
    getter data : String
    getter raw : JSON::Any
    getter level : Int32

    protected def initialize(@type, @level = 0, @data = "", @raw = "")
    end

    def self.parse(input : String | IO)
      json = JSON.parse(input)
      doc = Node.new(NodeType::Document, raw: json)
      parse(json, doc, 1)
      doc
    end

    private def self.parse(json : JSON::Any, node : Node, level : Int32)
      case json.raw
      when Array
        v = json.as_a
        v.each do |vv|
          n = Node.new(NodeType::Element, level, raw: vv)
          add_node(n, node)
          parse(vv, n, level + 1)
        end
      when Hash
        v = json.as_h
        keys = v.keys
        keys.sort!
        keys.each do |key|
          n = Node.new(NodeType::Element, level, key, v[key])
          add_node(n, node)
          parse(v[key], n, level + 1)
        end
      when String
        n = Node.new(NodeType::Text, level, json.as_s, json)
        add_node(n, node)
      when Float, Bool, Int
        n = Node.new(NodeType::Text, level, json.to_s, json)
        add_node(n, node)
      else
        raise "Unsupported type #{json}"
      end
    end

    private def self.add_node(n : Node, top : Node)
      if n.level == top.level
        top.next_sibling = n
        n.prev_sibling = top
        n.parent = top.parent
        if (p = top.parent)
          p.last_child = n
        end
      elsif n.level > top.level
        n.parent = top
        if top.first_child.nil?
          top.first_child = n
          top.last_child = n
        else
          t = top.last_child.not_nil!
          t.next_sibling = n
          n.prev_sibling = t
          top.last_child = n
        end
      end
    end

    def children
      arr = Array(Node).new
      n = first_child
      while n
        arr << n
        n = n.next_sibling
      end
      arr
    end

    # returns the value of the node and all of its child nodes.
    def content
      io = IO::Memory.new
      output(io, self)
      io.to_s
    end

    # select finds the first of child elements with the specified name
    def select(name : String)
      n = first_child
      while n
        return n if n.data == name
        n = n.next_sibling
      end
      nil
    end

    private def output(io, n)
      if n.type == NodeType::Text
        return io << n.data
      end
      child = n.first_child
      while child
        output(io, child)
        child = child.next_sibling
      end
    end
  end
end
