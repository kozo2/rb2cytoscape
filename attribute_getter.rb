require 'java'
require 'set'
require 'bio'

include_class 'cytoscape.Cytoscape'
include_class 'cytoscape.plugin.CytoscapePlugin'
include_class 'cytoscape.view.CyMenus'
include_class 'cytoscape.util.CytoscapeAction'
include_class 'cytoscape.data.CyAttributes'
include_class 'cytoscape.CyNode'
include_class 'cytoscape.CyEdge'
include_class 'cytoscape.CyNetwork'

include_class 'java.util.ArrayList'
include_class 'java.awt.event.ActionEvent'
include_class 'javax.swing.JOptionPane'

class RubyAction < CytoscapeAction
  def initialize()
    super("Plugin written in Ruby")
    setPreferredMenu("Plugins")
  end

  def actionPerformed(evt)
    JOptionPane.showMessageDialog(
    nil, "Start retrieving reaction and compound attribute", "JRuby on Cytoscape",
    JOptionPane::INFORMATION_MESSAGE)

    nodes = Cytoscape.getCyNodeList
    attrs = Cytoscape.getNodeAttributes
    serv  = Bio::KEGG::API.new

    node_id_for = Hash.new
    reaction_ids = ""
    compound_ids = ""

    nodes.each do |node|
      kegg_id = attrs.getAttribute(node.getIdentifier, "canonicalName")
      node_id_for[kegg_id] = node.getIdentifier

      case kegg_id
      when /^R/
        reaction_ids.concat(" " + kegg_id.sub("R", "rn:R")) 
      when /^C/
        compound_ids.concat(" " + kegg_id.sub("C", "cpd:C"))
      end

    end

    reaction_entries = serv.bget(reaction_ids)
    compound_entries = serv.bget(compound_ids)

    reaction_entries.split("\n///\n").each do |reaction_entry|
      rn = Bio::KEGG::REACTION.new(reaction_entry)
      node_id = node_id_for[rn.entry_id]
      attrs.setAttribute(node_id, "enzymes", rn.enzymes.join(', '))
      attrs.setAttribute(node_id, "equation", rn.equation)
      attrs.setAttribute(node_id, "pathways", rn.pathways.join(', '))
    end

    compound_entries.split("\n///\n").each do |compound_entry|
      cpd = Bio::KEGG::COMPOUND.new(compound_entry)
      node_id = node_id_for[cpd.entry_id]
      attrs.setAttribute(node_id, "formula", cpd.formula)
      attrs.setAttribute(node_id, "name", cpd.name)
      attrs.setAttribute(node_id, "mass", cpd.mass)
      attrs.setAttribute(node_id, "pathways", cpd.pathways.join(', '))
    end

    JOptionPane.showMessageDialog(
    nil, "Finished", "JRuby on Cytoscape",
    JOptionPane::INFORMATION_MESSAGE)
    )
  end
end

class RubyPlugin < CytoscapePlugin
  def register_menu
    cyMenus = Cytoscape.getDesktop().getCyMenus()
    cyMenus.addAction(RubyAction.new)
  end
end

RubyPlugin.new.register_menu()

