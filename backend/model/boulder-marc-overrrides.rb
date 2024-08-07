class MARCModel < ASpaceExport::ExportModel
  model_for :marc21

  include JSONModel


@resource_map = {
    [:id_0, :id_1, :id_2, :id_3] => :handle_id,
    [:ark_name] => :handle_ark,
    :notes => :handle_notes,
    # :finding_aid_description_rules => df_handler('fadr', '040', ' ', ' ', 'e'),
    # :id_0 => :handle_voyager_id,
    # :id => :handle_ref,
    # [:ead_location, :uri] => :handle_ead_loc,
    
}


  def self.from_resource(obj, opts={})
    marc = self.from_archival_object(obj,opts)
    marc.apply_map(obj, @resource_map)
    marc.leader_string = "00000npmaa2200000 i 4500"
    
    marc.leader_string[7] = obj.level == 'item' ? 'm' : 'c'

    marc.controlfield_string = assemble_controlfield_string(obj)

    marc
  end

  def df!(*args)
      @sequence ||= 0
      @sequence += 1
      @datafields[@sequence] = @@datafield.new(*args)
      @datafields[@sequence]
    end
  
  
    def df(*args)
      if @datafields.has_key?(args.to_s)
        @datafields[args.to_s]
      else
        @datafields[args.to_s] = @@datafield.new(*args)
        @datafields[args.to_s]
      end
    end
  

  #008 field
  def self.assemble_controlfield_string(obj)
    string = 'test'
    date = obj.dates[0] || {}
    string = obj['system_mtime'].scan(/\d{2}/)[1..3].join('')
    string += date['date_type'] == 'single' ? 's' : 'i'
    string += date['begin'] ? date['begin'][0..3] : "    "
    string += date['end'] ? date['end'][0..3] : "    "
    string += "xx "
    (35-(string.length)).times { string += ' ' }
    string += 'eng'
    string += ' c'
    string
  end

 

  
  ##245
  def handle_title(title, linked_agents, dates)
    creator = linked_agents.find {|a| a['role'] == 'creator'}
    date_codes = []

    # process dates first, if defined.
    unless dates.empty?
      dates = [["single", "inclusive", "range"], ["bulk"]].map {|types|
        dates.find {|date| types.include? date['date_type'] }
      }.compact

      dates.each do |date|
        code, val = nil
        code = date['date_type'] == 'bulk' ? 'g' : 'f'
        if date['expression']
          val = "#{date['expression']}."
        elsif date['end']
          val = "#{date['begin']}-#{date['end']}."
        else
          val = "#{date['begin']}."
        end
        date_codes.push([code, val])
      end
    end

    ind1 = creator.nil? ? "0" : "1"
    if date_codes.length > 0
      # we want to pass in all our date codes as separate subfield tags
      # e.g., with_sfs(['a', title], [code1, val1], [code2, val2]... [coden, valn])
      df('245', ind1, '0').with_sfs(['a', title + ","], *date_codes)
    else
      df('245', ind1, '0').with_sfs(['a', title])
    end
  end


  def handle_ark(ark_name)
    return if ark_name.nil?
    return unless [:arks_enabled]

    # If ARKs are enabled, add an 856
    #<datafield tag="856" ind1="4" ind2="2">
    #  <subfield code="z">Archival Resource Key:</subfield>
    #  <subfield code="u">ARK URL</subfield>
    #</datafield>

    if ark_url = ark_name['current']
      df('856', '4', '2').with_sfs(
        ['z', "Finding Aid (via ArchivesSpace)"],
        ['u', ark_url]
      ) unless ark_url.nil? || ark_url.empty?

    end
  end
end





  def handle_ead_loc(ead_loc, ead_uri)
    if ead_loc && !ead_loc.empty?

      df('856', '4', '2').with_sfs(
                                    ['z', "Finding aid (via ArchivesSpace)"],
                                    ['u', "https://"+ead_loc]
                                  )
      else
        df('856', '4', '2').with_sfs(
                                      ['z', "Finding aid (via ArchivesSpace)"],
                                      ['u', "https://archives.colorado.edu"+ead_uri]
                                    )
    end
  end
###

def handle_subjects(subjects)
  subjects.each do |link|
    subject = link['_resolved']
    term, *terms = subject['terms']
    code, ind2 =  case term['term_type']
                  when 'uniform_title'
                    ['630', source_to_code(subject['source'])]
                  when 'temporal'
                    ['648', source_to_code(subject['source'])]
                  when 'topical'
                    ['650', source_to_code(subject['source'])]
                  when 'geographic', 'cultural_context'
                    ['651', source_to_code(subject['source'])]
                  when 'genre_form', 'style_period'
                    ['655', source_to_code(subject['source'])]
                  when 'occupation'
                    ['656', '7']
                  when 'function'
                    ['656', '7']
                  else
                    ['650', source_to_code(subject['source'])]
                  end
    sfs = [['a', term['term']]]

    terms.each do |t|
      tag = case t['term_type']
            when 'uniform_title'; 't'
            when 'genre_form', 'style_period'; 'v'
            when 'topical', 'cultural_context'; 'x'
            when 'temporal'; 'y'
            when 'geographic'; 'z'
            end
      sfs << [tag, t['term']]
    end

    if ind2 == '7'
      sfs << ['2', subject['source']]
    end

    sfs << ['0', subject['authority_id']]

    ind1 = code == '630' ? "0" : " "
    df!(code, ind1, ind2).with_sfs(*sfs)
  end
end




  def handle_repo_code(repository, *finding_aid_language)
    repo = repository['_resolved']
    return false unless repo

    sfa = repo['org_code'] ? repo['org_code'] : "Repository: #{repo['repo_code']}"



    df('040', ' ', ' ').with_sfs(['a', 'COD'], ['b', 'eng'], ['e', 'rda'], ['c', 'COD'])

    df('049', ' ', ' ').with_sfs(['a', 'CODE'])
  end
###
  def handle_languages(lang_materials)
    nil
  end
###
def handle_language(langcode)
  #blocks output of 041
end
###

# def handle_voyager_id(id_0)
#   df('035', ' ', ' ').with_sfs(['a',"(CULAspace)" + id_0])
# end

# def handle_ref(id)
#   df('035', ' ', ' ').with_sfs(['a',"(CULAspaceURI)" + id.to_s])
# end

def handle_extents(extents)
  extents.each do |ext|
    e = ext['number'] + ' '
    t =  "#{I18n.t('enumerations.extent_extent_type.'+ext['extent_type'], :default => ext['extent_type'])}"

    if ext['container_summary']
      t << " (#{ext['container_summary']})"
    end

    if ext['dimensions']
      d = ext['dimensions']
    end



    df!('300').with_sfs(['a', e + t])
  end
end



###

def handle_id(*ids)
  ids.reject!{|i| i.nil? || i.empty? }
  df('099', ' ', '9').with_sfs(['a', ids.join('.')])
end

###

#   def handle_primary_creator(linked_agents)
#     link = linked_agents.find{|a| a['role'] == 'creator'}
#     return nil unless link
#     return nil unless link["_resolved"]["publish"] || @include_unpublished

#     creator = link['_resolved']
#     name = creator['display_name']

#     ind2 = ' '

#     relator_sfs = []
#     if link['relator']
#       handle_relators(relator_sfs, link['relator'])
#     else
#       relator_sfs << ['e', 'creator']
#     end

#     case creator['agent_type']

#     when 'agent_corporate_entity'
#       code = '110'
#       ind1 = '2'
#       sfs = gather_agent_corporate_subfield_mappings(name, relator_sfs, creator)

#     when 'agent_person'
#       ind1  = name['name_order'] == 'direct' ? '0' : '1'
#       code = '100'
#       sfs = gather_agent_person_subfield_mappings(name, relator_sfs, creator)

#     when 'agent_family'
#       code = '100'
#       ind1 = '3'
#       sfs = gather_agent_family_subfield_mappings(name, relator_sfs, creator)

#     end

#     df(code, ind1, ind2).with_sfs(*sfs)
#   end

#   def handle_other_creators(linked_agents)
#     creators = linked_agents.select {|a| a['role'] == 'creator'}[1..-1] || []
#     creators = creators + linked_agents.select {|a| a['role'] == 'source'}

#     creators.each_with_index do |link, i|
#       next unless link["_resolved"]["publish"] || @include_unpublished

#       creator = link['_resolved']
#       name = creator['display_name']
#       role = link['role']

#       relator_sfs = []
#       if link['relator']
#         handle_relators(relator_sfs, link['relator'])
#       elsif role == 'source'
#         relator_sfs << ['e', 'former owner']
#       else
#         relator_sfs << ['e', 'creator']
#       end

#       ind2 = ' '

#       case creator['agent_type']

#       when 'agent_corporate_entity'
#         code = '710'
#         ind1 = '2'
#         sfs = gather_agent_corporate_subfield_mappings(name, relator_sfs, creator)

#       when 'agent_person'
#         ind1  = name['name_order'] == 'direct' ? '0' : '1'
#         code = '700'
#         sfs = gather_agent_person_subfield_mappings(name, relator_sfs, creator)

#       when 'agent_family'
#         ind1 = '3'
#         code = '700'
#         sfs = gather_agent_family_subfield_mappings(name, relator_sfs, creator)

#       end

#       df(code, ind1, ind2, i).with_sfs(*sfs)
#     end
#   end

#   def handle_agents(linked_agents)
#     handle_primary_creator(linked_agents)
#     handle_other_creators(linked_agents)

#     subjects = linked_agents.select {|a| a['role'] == 'subject'}

#     subjects.each_with_index do |link, i|
#       subject = link['_resolved']
#       name = subject['display_name']
#       relator = link['relator']
#       terms = link['terms']
#       ind2 = source_to_code(name['source'])

#       relator_sfs = []
#       if link['relator']
#         handle_relators(relator_sfs, link['relator'])
#       end

#       case subject['agent_type']

#       when 'agent_corporate_entity'
#         code = '610'
#         ind1 = '2'
#         sfs = [
#           ['a', name['primary_name']],
#           ['b', name['subordinate_name_1']],
#           ['b', name['subordinate_name_2']],
#           ['n', name['number']],
#           ['g', name['qualifier']],
#         ]

#       when 'agent_person'
#         joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
#         name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)
#         ind1 = name['name_order'] == 'direct' ? '0' : '1'
#         code = '600'
#         sfs = [
#           ['a', name_parts],
#           ['b', name['number']],
#           ['c', %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ')],
#           ['q', name['fuller_form']],
#           ['d', name['dates']],
#           ['g', name['qualifier']],
#         ]

#       when 'agent_family'
#         code = '600'
#         ind1 = '3'
#         sfs = [
#           ['a', name['family_name']],
#           ['c', name['prefix']],
#           ['d', name['dates']],
#           ['g', name['qualifier']],
#         ]

#       end

#       terms.each do |t|
#         tag = case t['term_type']
#               when 'uniform_title'; 't'
#               when 'genre_form', 'style_period'; 'v'
#               when 'topical', 'cultural_context'; 'x'
#               when 'temporal'; 'y'
#               when 'geographic'; 'z'
#               end
#         sfs << [(tag), t['term']]
#       end

#       if ind2 == '7'
#         create_sfs2 = %w(local ingest)
#         sfs << ['2', 'local'] if create_sfs2.include?(subject['display_name']['source'])
#       end

#       df(code, ind1, ind2, i).with_sfs(*sfs)
#     end
#   end



def handle_notes(notes)

  notes.each do |note|

    prefix =  case note['type']
              when 'dimensions'; "Dimensions"
              when 'physdesc'; "Physical Description note"
              when 'materialspec'; "Material Specific Details"
              when 'physloc'; "Location of resource"
              when 'phystech'; "Physical Characteristics / Technical Requirements"
              when 'physfacet'; "Physical Facet"
              when 'processinfo'; "Processing Information"
              when 'separatedmaterial'; "Materials Separated from the Resource"
              else; nil
              end

              marc_args = case note['type']
                  #   when 'arrangement', 'fileplan'
                  #     ['351', 'a']
                  #   when 'odd', 'dimensions', 'physdesc', 'materialspec', 'physloc', 'phystech', 'physfacet', 'processinfo', 'separatedmaterial'
                  #     ['500','a']
                  # when 'odd', 'dimensions', 'materialspec', 'phystech', 'physfacet', 'processinfo', 'separatedmaterial'
                  #     ['500','a']
                  
                  # when 'accessrestrict'
                  #     ['506','a']  
                # when 'scopecontent'
                #   ['520', '3', ' ', 'a']
                when 'abstract'
                  ['520', '3', ' ', 'a']
                # when 'prefercite'
                #   ['524', ' ', ' ', 'a']
                when 'acqinfo'
                  ind1 = note['publish'] ? '1' : '0'
                  ['541', ind1, ' ', 'a']
                when 'relatedmaterial'
                  ind1 = note['publish'] ? '1' : '0'
                  ['544', ind1, ' ', 'a']
                # when 'bioghist'
                #     ['545',ind1,' ','a']
                when 'custodhist'
                  ind1 = note['publish'] ? '1' : '0'
                  ['561', ind1, ' ', 'a']
                when 'appraisal'
                  ind1 = note['publish'] ? '1' : '0'
                  ['583', ind1, ' ', 'a']
                when 'accruals'
                  ['584', 'a']
                when 'altformavail'
                  ['535', '2', ' ', 'a']
                when 'originalsloc'
                  ['535', '1', ' ', 'a']
                # when 'userestrict', 'legalstatus'
                #   ['540', 'a']
                # when 'langmaterial'
                #   ['546', 'a']
                when 'otherfindaid'
                  ['555', '0', ' ', 'a']
                else
                  nil
                end
                

    unless marc_args.nil?
      text = prefix ? "#{prefix}: " : ""
      text += ASpaceExport::Utils.extract_note_text(note, @include_unpublished, true)

      # only create a tag if there is text to show (e.g., marked published or exporting unpublished)
      if text.length > 0
        df!(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
      end
    end

  end
end


