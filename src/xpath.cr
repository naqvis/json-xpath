require "xpath2"
require "./node"

module JSONXPath
  class Node
    # Searches this node for XPath *path*. Returns first matched `HTML::Node` or `nil`
    def xpath(path : String) : Node?
      expr = XPath2.compile(path)
      t = expr.select(JSONNavigator.new(self, self))
      return t.current.as(XPath2::NodeNavigator).curr if t.move_next
      nil
    end

    # Searches this node for XPath *path*. Returns all of the matched `HTML::Node`
    def xpath_nodes(path : String) : Array(Node)
      elems = Array(Node).new
      expr = XPath2.compile(path)
      if (t = expr.select(JSONNavigator.new(self, self)))
        while t.move_next
          elems << t.current.as(XPath2::NodeNavigator).curr
        end
      end
      elems
    end

    # Searches this node for XPath *path* and restricts the return type to `Bool`.
    def xpath_bool(path : String)
      xpath_evaluate(path).as(Bool)
    end

    # Searches this node for XPath *path* and restricts the return type to `Float64`.
    def xpath_float(path : String)
      xpath_evaluate(path).as(Float64)
    end

    # Searches this node for XPath *path* and restricts the return type to `String`.
    def xpath_bool(path : String)
      xpath_evaluate(path).as(String)
    end

    # Searches this node for XPath *path* and return result with appropriate type
    # `(Bool | Float64 | String | NodeIterator | Nil)`
    def xpath_evaluate(path)
      expr = XPath2.compile(path)
      expr.evaluate(JSONNavigator.new(self, self))
    end
  end

  private class JSONNavigator
    include XPath2::NodeNavigator
    property curr : Node
    property root : Node

    def initialize(@curr, @root)
    end

    def current
      @curr
    end

    def node_type : XPath2::NodeType
      case curr.type
      when .text?
        XPath2::NodeType::Text
      when .document?
        XPath2::NodeType::Root
      when .element?
        XPath2::NodeType::Element
      else
        raise "Uknown node type: #{curr.type}"
      end
    end

    def local_name : String
      @curr.data
    end

    def prefix : String
      ""
    end

    def value : String
      case @curr.type
      when .text?
        @curr.data
      when .element?
        @curr.content
      else
        ""
      end
    end

    def copy : XPath2::NodeNavigator
      JSONNavigator.new(@curr, @root)
    end

    def move_to_root
      @curr = @root
    end

    def move_to_parent
      if (node = @curr.parent)
        @curr = node
        return true
      end
      false
    end

    def move_to_next_attribute : Bool
      false
    end

    def move_to_child : Bool
      if (node = @curr.first_child)
        @curr = node
        return true
      end
      false
    end

    def move_to_first : Bool
      return false if @curr.prev_sibling.nil?
      node = @curr.prev_sibling
      while node
        @curr = node
        node = @curr.prev_sibling
      end
      true
    end

    def to_s
      self.value
    end

    def move_to_next : Bool
      if (node = @curr.next_sibling)
        @curr = node
        return true
      end
      false
    end

    def move_to_previous : Bool
      if (node = @curr.prev_sibling)
        @curr = node
        return true
      end
      false
    end

    def move_to(nav : XPath2::NodeNavigator) : Bool
      if (node = nav.as?(JSONNavigator)) && (node.root == @root)
        @curr = node.curr
        true
      else
        false
      end
    end
  end
end
