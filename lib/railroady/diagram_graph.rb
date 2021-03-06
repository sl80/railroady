# RailRoady - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details

require "digest"

# RailRoady diagram structure
class DiagramGraph

  def initialize
    @diagram_type = ''
    @show_label = false
    @nodes = []
    @edges = []
  end

  def add_node(node)
    @nodes << node
  end

  def add_edge(edge)
    @edges << edge
  end

  def diagram_type= (type)
    @diagram_type = type
  end

  def show_label= (value)
    @show_label = value
  end


  # Generate DOT graph
  def to_dot
    return dot_header +
           @nodes.map{|n| dot_node n[0], n[1], n[2]}.join +
           @edges.map{|e| dot_edge e[0], e[1], e[2], e[3]}.join +
           dot_footer
  end

  # Generate XMI diagram 
  def to_xmi
     i=1;
     nodes = @nodes.map{ |n| {:type => n[0], :name => n[1], :attributes => n[2]}  }
     edges = @edges.map{ |n| {:type =>n[0], :from => n[1], :to => n[2], :name => n[3], :nr => i+=1}  }
     return xmi_header +
       nodes.map{ |n| xmi_node n }.join +
       edges.map{ |e| xmi_edge e }.join +
       xmi_footer
  end
  
  private
  
  
  def xmi_header
    <<-eos
<?xml version = '1.0' encoding = 'UTF-8' ?>
      <XMI xmi.version = '1.2' xmlns:UML = 'org.omg.xmi.namespace.UML' >
        <XMI.header>    
          <XMI.documentation>
            <XMI.exporter>railroady</XMI.exporter>
            <XMI.exporterVersion></XMI.exporterVersion>
          </XMI.documentation>
          <XMI.metamodel xmi.name="UML" xmi.version="1.4"/>
        </XMI.header>
      <XMI.content>
        <UML:Model xmi.id = '123456'
          name = 'Rails' isSpecification = 'false' isRoot = 'false' isLeaf = 'false'
          isAbstract = 'false'>
          <UML:Namespace.ownedElement>
    eos
  end
  
  def xmi_footer
    <<-eos
            </UML:Namespace.ownedElement>
          </UML:Model>
        </XMI.content>
      </XMI>
    eos
  end
  
  def xmi_node(node)
    <<-eos
      <UML:Class xmi.id = '#{md5 node[:name]}'
        name = '#{node[:name]}' visibility = 'public' isSpecification = 'false' isRoot = 'false'
        isLeaf = 'false' isAbstract = 'false' isActive = 'false'>
      </UML:Class>
    eos
  end
  
  def xmi_edge(edge)
    case edge[:type]
      
      when "one-one", "one-many", "many-many"
        return  <<-eos
              <UML:Association xmi.id = '123-#{edge[:nr]}'
                name = '' isSpecification = 'false' isRoot = 'false' isLeaf = 'false' isAbstract = 'false'>
                <UML:Association.connection>
                  <UML:AssociationEnd xmi.id = '123-#{edge[:nr]}-1'
                    visibility = 'public' isSpecification = 'false' isNavigable = 'false' ordering = 'unordered'
                    aggregation = '#{edge[:type] == 'many-many' ? 'none' : 'aggregate'}' targetScope = 'instance' changeability = 'changeable'>
                    <UML:AssociationEnd.participant>
                      <UML:Class xmi.idref = '#{md5 edge[:from]}'/>
                    </UML:AssociationEnd.participant>
                  </UML:AssociationEnd>
                  <UML:AssociationEnd xmi.id = '123-#{edge[:nr]}-2'
                    visibility = 'public' isSpecification = 'false' isNavigable = 'true' ordering = 'unordered'
                    aggregation = 'none' targetScope = 'instance' changeability = 'changeable'>
                    <UML:AssociationEnd.participant>
                      <UML:Class xmi.idref = '#{md5 edge[:to]}'/>
                    </UML:AssociationEnd.participant>
                  </UML:AssociationEnd>
                </UML:Association.connection>
              </UML:Association>
        eos
     when "is-a"
        return  <<-eos
          <UML:Generalization xmi.id = '234-#{edge[:nr]}'
             isSpecification = 'false'>
             <UML:Generalization.child>
               <UML:Class xmi.idref = '#{md5 edge[:to]}'/>
             </UML:Generalization.child>
             <UML:Generalization.parent>
               <UML:Class xmi.idref = '#{md5 edge[:from]}'/>
             </UML:Generalization.parent>
           </UML:Generalization>
        eos
     end
     return ""  
  end
  
  
  def md5(string)
    Digest::MD5.hexdigest(string)
  end
  
  

  # Build DOT diagram header
  def dot_header
    result = "digraph #{@diagram_type.downcase}_diagram {\n" +
             "\tgraph[overlap=false, splines=true]\n"
    result += dot_label if @show_label
    return result
  end

  # Build DOT diagram footer
  def dot_footer
    return "}\n"
  end

  # Build diagram label
  def dot_label
    return "\t_diagram_info [shape=\"plaintext\", " +
           "label=\"#{@diagram_type} diagram\\l" +
           "Date: #{Time.now.strftime "%b %d %Y - %H:%M"}\\l" +
           "Migration version: " +
           "#{ActiveRecord::Migrator.current_version}\\l" +
           "Generated by #{APP_HUMAN_NAME} #{APP_VERSION}\\l"+
		   "http://railroady.prestonlee.com" +
           "\\l\", fontsize=13]\n"
  end

  # Build a DOT graph node
  def dot_node(type, name, attributes=nil)
    case type
      when 'model'
           options = 'shape=Mrecord, label="{' + name + '|'
           options += attributes.join('\l')
           options += '\l}"'
      when 'model-brief'
           options = ''
      when 'class'
           options = 'shape=record, label="{' + name + '|}"'
      when 'class-brief'
           options = 'shape=box'
      when 'controller'
           options = 'shape=Mrecord, label="{' + name + '|'
           public_methods    = attributes[:public].join('\l')
           protected_methods = attributes[:protected].join('\l')
           private_methods   = attributes[:private].join('\l')
           options += public_methods + '\l|' + protected_methods + '\l|' +
                      private_methods + '\l'
           options += '}"'
      when 'controller-brief'
           options = ''
      when 'module'
           options = 'shape=box, style=dotted, label="' + name + '"'
      when 'aasm'
           # Return subgraph format
           return "subgraph cluster_#{name.downcase} {\n\tlabel = #{quote(name)}\n\t#{attributes.join("\n  ")}}"
    end # case
    return "\t#{quote(name)} [#{options}]\n"
  end # dot_node

  # Build a DOT graph edge
  def dot_edge(type, from, to, name = '')
    options =  name != '' ? "label=\"#{name}\", " : ''
    case type
      when 'one-one'
           options += 'arrowtail=odot, arrowhead=dot, dir=both'
      when 'one-many'
           options += 'arrowtail=odot, arrowhead=crow, dir=both'
      when 'many-many'
           options += 'arrowtail=crow, arrowhead=crow, dir=both'
      when 'is-a'
           options += 'arrowhead="none", arrowtail="onormal"'
      when 'event'
           options += "fontsize=10"
    end
    return "\t#{quote(from)} -> #{quote(to)} [#{options}]\n"
  end # dot_edge

  # Quotes a class name
  def quote(name)
    '"' + name.to_s + '"'
  end

end # class DiagramGraph
