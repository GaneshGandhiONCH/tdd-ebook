# This code was generated by dot2ruby.g

require 'rubygems'
require 'graphviz'
require './Config'

def add_object(name, graph)
  graph.add_nodes name, fontsize: $DEFAULT_FONT_SIZE, label: '', shape: :circle
end

def add_invisible(name, graph)
  graph.add_nodes name, fontsize: $DEFAULT_FONT_SIZE, label: '', style: :invisible 
end


graph_g = GraphViz.digraph( "G", use: :neato ) { |graph_g|
  apply_config_to graph_g
  graph_g[:fontsize] = 5
  
  o1 = add_object "o1", graph_g
  o2 = add_object "o2", graph_g
  o3 = add_object "o3", graph_g
  o4 = add_object "o4", graph_g
  o5 = add_object "o5", graph_g
  o6 = add_object "o6", graph_g
  o7 = add_object "o7", graph_g
  o8 = add_object "o8", graph_g
  o9 = add_object "o9", graph_g
  o10 = add_object "o10", graph_g
  o11 = add_object "o11", graph_g
  o12 = add_invisible "o12", graph_g
  o13 = add_invisible "o13", graph_g
  o14 = add_invisible "o14", graph_g
  
  graph_g.add_edges o1, o3
  graph_g.add_edges o3, o2
  graph_g.add_edges o3, o7
  graph_g.add_edges o4, o3
  graph_g.add_edges o5, o4
  graph_g.add_edges o6, o5
  graph_g.add_edges o7, o6
  graph_g.add_edges o7, o8, len: '1.1'
  graph_g.add_edges o7, o11
  graph_g.add_edges o8, o9
  graph_g.add_edges o10, o6
  graph_g.add_edges o11, o9
  graph_g.add_edges o11, o10
  graph_g.add_edges o2, o13, style: :dashed 
  graph_g.add_edges o9, o14, style: :dashed 
  graph_g.add_edges o12, o1, style: :dashed 
  
}

graph_g.output(:svg => "WebOfObjects.svg")
graph_g.output(:png => "WebOfObjects.png")