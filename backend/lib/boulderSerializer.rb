class BoulderMARCSerializer

  def initialize(record)
    @record = record
  end

  def leader_string
    result = @record.leader_string
    #changing 8th position to 'a'
    result[8] = 'a'
    result

  end

  def controlfield_string
    result = @record.controlfield_string
  end

  def controlfields
    cf = []
    # org_codes = %w(NNU-TL NNU-F NyNyUA NyNyUAD NyNyUCH NBPol NyBlHS NHi)
    # org_code = get_repo_org_code
    # cf << add_003_tag(org_code) if org_codes.include?(org_code)
    # cf << add_005_tag
    # @record.controlfields = cf
  end

  def datafields

    extra_fields = []
    @field_pairs = []

    # Do this on all records
    # extra_fields << add_024_tag
    # extra_fields << add_035_tag
    extra_fields << add_043_tag
    extra_fields << add_506_tag
    extra_fields << add_655_tag
    extra_fields << add_710_tag
    

    # Only process the 853, 863 and 949 if the records is from tamwag, fales, nyuarchives, or Poly Archives
    # if(get_allowed_values.has_key?(get_record_repo_value)) then
    #   extra_fields << add_853_tag
    #   if @record.aspace_record['top_containers']
    #     top_containers = @record.aspace_record['top_containers']
    #     top_containers.each_key{ |id|
    #       info = top_containers[id]
    #       loc = info[:location]
    #       if(info[:barcode] != nil && loc != nil && /Flat file/.match?(loc) != true && /Flat File/.match?(loc) != true ) then
    #         @field_pairs << add_863_tag(info)
    #         @field_pairs << add_949_tag(info)
    #       end
    #     }
    #   end
    # end

    @sort_combined = (@record.datafields + extra_fields).sort_by(&:tag)
    # 863 and 949 pairs are not to be sorted
    # sticking them at the end since the highest tag
    # before 863 is 856
    # this is a hard coded assumption but it's faster
    # There is a method below that does not have that assumption
    # Will call in case things change in marc record
    @sort_combined + @field_pairs


    # the method below is in case there are
    # marc tags higher than 863 in the marc record
    # and the pairs need to be inserted in order
    # not calling this now because it's slower
    # arrange_datafields
  end

  def arrange_datafields
    min_tag = 863
    last_index = nil
    final_results = []
    # Assumed that sort_combined is sorted
    # in tag order
    @sort_combined.each_with_index do |f,i|
      last_index = i if f.tag.to_i < min_tag
    end
    if last_index == @sort_combined.index(@sort_combined.last)
      final_results = @sort_combined + @field_pairs
    elsif last_index < @sort_combined.index(@sort_combined.last)
      #slice and dice
      temp_array = []
      @sort_combined.slice(0..last_index).each do |i|
        temp_array << i
      end
      @field_pairs.each { |f| temp_array << f }
      start = last_index + 1
      array_last_index = @sort_combined.index(@sort_combined.last)
      final_results = temp_array + @sort_combined.slice(start..array_last_index)
    else
      raise "ERROR: Please check data"
    end

    final_results

  end


  def get_datafield_hash(tag,ind1,ind2)
    {tag: tag, ind1: ind1, ind2: ind2}
  end

  def get_subfield_hash(code,value)
    {code:code, value:value}
  end

  def get_controlfield_hash(tag,text)
    {tag:tag, text: text}
  end


  # def add_005_tag
  #   value = format_timestamp
  #   controlfield_hsh = get_controlfield_hash('005',value)
  #   cf = BoulderCustomTag.new(controlfield_hsh)
  #   cf.add_controlfield_tag
  # end

  

  # def add_003_tag(org_code)
  #   controlfield_hsh = get_controlfield_hash('003',org_code)
  #   cf = BoulderCustomTag.new(controlfield_hsh)
  #   cf.add_controlfield_tag
  # end

  def add_024_tag
    subfields_hsh = {}
    value = "(#{get_repo_org_code})#{check_multiple_ids}"
    datafield_hsh = get_datafield_hash('024','7',' ')
    subfields_hsh[1] = get_subfield_hash('a',value)
    subfields_hsh[2] = get_subfield_hash('2','local')
    datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
    datafield.add_datafield_tag
  end
  def add_035_tag
    org_code = get_repo_org_code
    value = "(#{get_repo_org_code})#{check_multiple_ids}-#{format_timestamp('date')}"
    subfields_hsh = {}
    datafield_hsh = get_datafield_hash('035','','')
    subfields_hsh[1] = get_subfield_hash('a',value)
    datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
    datafield.add_datafield_tag
  end

  def add_043_tag
    subfields_hsh = {}
    datafield_hsh = get_datafield_hash('043',' ',' ')
    subfields_hsh[1] = get_subfield_hash('a', "")
    datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
    datafield.add_datafield_tag
  end



  def add_506_tag
    restrictions_apply = @record.aspace_record['restrictions_apply']
    stringv = restrictions_apply.to_s
    
    # restrictions_text = restrictions_apply ? "Collection is open for research use." : "Collection is restricted."
    subfields_hsh = {}
    datafield_hsh = get_datafield_hash('506','0',' ')
    subfields_hsh[1] = get_subfield_hash('a', stringv)
    datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
    datafield.add_datafield_tag
end

# def add_506_tag
#   restrictions_apply = @record.aspace_record['restrictions_apply']
  
#   if restrictions_apply == 'False'
#       indicator_value = '1' # If restrictions apply is false, set indicator value to 1
#       restrictions_text = "OPEN."
#   elsif restrictions_apply == 'True'
#       indicator_value = '0' # If restrictions apply is true or nil, set indicator value to 0
#       restrictions_text = "CLOSED."
#   elsif restrictions_apply.nil?
#     restrictions_text = 'NIL'
#   end
  
#   subfields_hsh = {}
#   datafield_hsh = get_datafield_hash('506', indicator_value, ' ')
#   subfields_hsh[1] = get_subfield_hash('a', restrictions_text)
  
#   datafield = BoulderCustomTag.new(datafield_hsh, subfields_hsh)
#   datafield.add_datafield_tag
# end



  def add_655_tag
    subfields_hsh = {}
    datafield_hsh = get_datafield_hash('655',' ','7')
    subfields_hsh[1] = get_subfield_hash('a', "Manuscripts.")
    subfields_hsh[2] = get_subfield_hash('2', "lcgft")
    
    datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
    datafield.add_datafield_tag
  end


  def add_710_tag
    v1 = "University of Colorado Boulder."
    v2 = "University Libraries."
    v3 = "Rare and Distinctive Collections."
    subfields_hsh = {}
    datafield_hsh = get_datafield_hash('710','2',' ')
    subfields_hsh[1] = get_subfield_hash('a', v1)
    subfields_hsh[2] = get_subfield_hash('b', v2)
    subfields_hsh[3] = get_subfield_hash('b', v3)
    datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
    datafield.add_datafield_tag
  end

  # def add_853_tag
  #   subfields_hsh = {}
  #   datafield_hsh = get_datafield_hash('853','0','0')
  #   # have to have a hash by position as the key
  #   # since the subfield positions matter
  #   subfields_hsh[1] = get_subfield_hash('8','1')
  #   subfields_hsh[2] = get_subfield_hash('a','Box')
  #   datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
  #   datafield.add_datafield_tag
  # end

  # def add_863_tag(info)
  #   subfields_hsh = {}
  #   datafield_hsh = get_datafield_hash('863','','')
  #   # have to have a hash by position as the key
  #   # since the subfield positions matter
  #   subfields_hsh[1] = get_subfield_hash('8',"1.#{info[:indicator]}")
  #   subfields_hsh[2] = get_subfield_hash('a',info[:indicator])
  #   subfields_hsh[3] = get_subfield_hash('p',info[:barcode]) if info[:barcode]
  #   datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
  #   datafield.add_datafield_tag
  # end

  # def add_949_tag(info)

  #   subfields_hsh = {}
  #   datafield_hsh = get_datafield_hash('949','0','')
  #   # have to have a hash by position as the key
  #   # since the subfield positions matter
  #   subfields_hsh[1] = get_subfield_hash('a','NNU')
  #   subfields_hsh[4] = get_subfield_hash('t','4')
  #   subfields_hsh[5] = generate_subfield_j
  #   subfields_hsh[6] = get_subfield_hash('m','MIXED')
  #   subfields_hsh[7] = get_subfield_hash('i','04')
  #   subfields_hsh[8] = get_location(info[:location])
  #   subfields_hsh[9] = get_subfield_hash('p',info[:barcode]) if info[:barcode]
  #   subfields_hsh[10] = get_subfield_hash('w',"Box #{info[:indicator]}")
  #   subfields_hsh[11] = get_subfield_hash('e',info[:indicator])
  #   # merge repo code hash with existing subfield code hash
  #   subfields_hsh.merge!(process_repo_code)
  #   datafield = BoulderCustomTag.new(datafield_hsh,subfields_hsh)
  #   datafield.add_datafield_tag
  # end

  # def get_repo_org_code
  #   @record.aspace_record['repository']['_resolved']['org_code']
  # end

  # def get_record_repo_value
  #   code = @record.aspace_record['repository']['_resolved']['repo_code']
  #   code
  # end

  # def get_allowed_values
  #   allowed_values = {}
  #   allowed_values['tamwag'] = { b: 'BTAM', c: 'TAM' }
  #   allowed_values['fales'] = { b: 'BFALE', c: 'FALES'}
  #   allowed_values['archives'] = { b: 'BARCH', c: 'MAIN' }
  #   allowed_values['Poly Archives'] = { b: 'NDIBN', c: 'ARCH'}
  #   allowed_values
  # end

  def get_repo_code_values
    repo_code = nil
    repo_value = get_record_repo_value
    # returning the repo value from the record
    # in a consistent case
    record_repo_value = repo_value.downcase ? repo_value : repo_value.downcase
    # get valid values
    allowed_values = get_allowed_values
    # get subfield values for repo codes
    allowed_values.each_key { |code|
      case record_repo_value
      when code
        repo_code = allowed_values[code]
      end
    }
    unless repo_code
      raise "ERROR: Repo code must be one of these: #{allowed_values.keys}
      and not this value: #{record_repo_value}"
    end
    repo_code
  end
  

  def process_repo_code
    subfields = {}
    # get subfield values for repo code
    repo_code = get_repo_code_values
    # creating a subfield hash
    repo_code.each_key{ |code|
      position = code.to_s == 'b' ? 2 : 3
      subfields[position] = get_subfield_hash(code,repo_code[code])
    }
    subfields
  end

  def check_multiple_ids
    j_id = @record.aspace_record['id_0']
    j_other_ids = []
    if @record.aspace_record['id_1'] or @record.aspace_record['id_2'] or
        @record.aspace_record['id_3']
      j_other_ids << @record.aspace_record['id_1']
      j_other_ids << @record.aspace_record['id_2']
      j_other_ids << @record.aspace_record['id_3']
      # adding the first id as the first element of the array
      j_other_ids.unshift(j_id)
      j_other_ids.compact!
      j_other_ids = j_other_ids.join(".")
    end
    # if no other ids, assign id_0 else assign the whole array of ids
    j_id = j_other_ids.size == 0 ? j_id : j_other_ids
  end

  def generate_subfield_j
    id = check_multiple_ids
    get_subfield_hash('j',id)
  end

  # def location_hsh
  #   {
  #       "Clancy Cullen [Offsite]" => "DM",
  #       "Bern Dibner Library [Offsite Prep]" => "ON",
  #       "Bobst [Offsite Prep]" => "ON"
  #   }
  # end

  def get_location(location_info)
    loc_hsh = location_hsh
    # if location is one of the keys in location_hash,
    # output the value
    # else a blank subfield
    location = loc_hsh.key?(location_info) ? loc_hsh[location_info] : ''
    # creating a subfield hash
    get_subfield_hash('s',location)
  end

  def format_timestamp(type = 'timestamp')
    ts = @record.aspace_record['user_mtime']
    value = nil
    case type
    when 'timestamp'
      value = ts.gsub(/-|T|:|Z/,"") + ".0"
    when 'date'
      value = ts.split('T')[0]
      value = value.gsub('-','')
    end
    raise "ERROR: incorrect argument passed: #{type}. Should be either date or timestamp" if value.nil?

    value
  end
end
