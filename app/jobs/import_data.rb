class ImportData
    
    @queue = :import_data

    def self.perform(name, language, initial_latitude, final_latitude, initial_longitude, final_longitude)

      puts ""
      puts "  --- Start executing Import Data Job => " + Time.new.inspect + " ---"
      puts ""
      puts "      >> Name: " + name
      puts "      >> Language: " + language
      puts ""

      puts "      || ETL execution ||"
      # Log starting
      OperationalLog.create(source: "jobs/import_data", event: "import_data - starting job", 
        comment: "Name: " + name + 
            " | Language: " + language + 
            " | Initial Latitude: " + initial_latitude.to_s + 
            " | Final Latitude: " + final_latitude.to_s + 
            " | Initial Longitude: " + initial_longitude.to_s + 
            " | Final Latitude: " + final_longitude.to_s
                )

      # Get area data set
      puts "      -> Get data from Area and Wikipedia"
      origin, category, content = extractData(language, initial_latitude, final_latitude, initial_longitude, final_longitude)

      puts "      -> Insert Import, ImportPoint, ImportDetail, ImportThematicPoint"
      loadData(origin, category, content, name, language, initial_latitude, final_latitude, initial_longitude, final_longitude)

      # Log ending
      OperationalLog.create(source: "jobs/import_data", event: "import_data - ending job") 

      puts ""
      puts "  --- End executing LoadPoint Job => " + Time.new.inspect + " ---"
      puts ""

    end

    def self.extractData(language, initial_latitude, final_latitude, initial_longitude, final_longitude)
    
        originSet = []
        categorySet = []
        contentSet = []

        # >> Calculate area zones
        zones = [
            "https://" + language + ".wikipedia.org/w/api.php?format=json&action=query&list=geosearch&gslimit=500&gsbbox=" + initial_latitude.to_s + "|" + initial_longitude.to_s + "|" + final_latitude.to_s + "|" + final_longitude.to_s
        ]

        puts "          |_> Zones numbers: " + zones.count.to_s
        OperationalLog.create(source: "jobs/import_data", event: "import_data - number of zones", comment: "Zones number: " + zones.count.to_s)

        # Get articles inside a zone
        zones.each do |url|

            OperationalLog.create(source: "jobs/import_data", event: "import_data - extract data query", comment: url) 
            
            wikipediaResponse = HTTParty.get(url, format: :plain)
            wikipediaData = JSON.parse(wikipediaResponse, symbolize_names: true)
            
            parseData = wikipediaData[:query][:geosearch]
            parseData.each do |row|
                wikibaseResponse = HTTParty.get("https://" + language + ".wikipedia.org/w/api.php?format=json&action=query&prop=pageprops&ppprop=wikibase_item&redirects=1&pageids=" + row[:pageid].to_s, format: :plain)
                wikibaseData = JSON.parse(wikibaseResponse)
                originSet.push({
                    :wikipedia_id => row[:pageid],
                    :wikibase_id => wikibaseData["query"]["pages"][row[:pageid].to_s]["pageprops"]["wikibase_item"],
                    :title => row[:title], 
                    :latitude => row[:lat], 
                    :longitude => row[:lon],
                })

            end
            
        end

        OperationalLog.create(source: "jobs/import_data", event: "import_data - origin set", comment: "Number of points: " + originSet.count.to_s) 

        originSet.each do |row|
        
            categoryResponse = HTTParty.get("https://www.wikidata.org/w/api.php?action=wbgetentities&props=claims&format=json&ids=" + row[:wikibase_id], format: :plain)
            categoryData = JSON.parse(categoryResponse)
            
            begin
                loopRange = 0 ... categoryData["entities"][row[:wikibase_id]]["claims"]["P31"].count
                loopRange.each do |iteration|
                    id = categoryData["entities"][row[:wikibase_id]]["claims"]["P31"][iteration]["mainsnak"]["datavalue"]["value"]["id"]
                    categoryNameResponse = HTTParty.get("https://www.wikidata.org/w/api.php?action=wbgetentities&props=labels&languages=en&format=json&ids=" + id, format: :plain)
                    categoryNameData = JSON.parse(categoryNameResponse)
                    begin
                        category = categoryNameData["entities"][id]["labels"]["en"]["value"]
                        categorySet.push({
                            :wikipedia_id => row[:wikipedia_id],
                            :category_id => id,
                            :category_name => category
                        })
                    rescue
                        puts " >>>>> Category Error"
                    end
                end                
            rescue
                puts " >>>>> Without Category"
            end
        end

        OperationalLog.create(source: "jobs/import_data", event: "import_data - category set", comment: "Number of thematics: " + categorySet.count.to_s) 

        originSet.each do |row|
            textResponse = HTTParty.get("https://es.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&explaintext&redirects=1&pageids=" + row[:wikipedia_id].to_s, format: :plain)
            textData = JSON.parse(textResponse)

            text = textData["query"]["pages"][row[:wikipedia_id].to_s]["extract"]

            textLength = text.length


            text = text.gsub("=====", "#####")
            text = text.gsub("====", "####")
            text = text.gsub("===", "###")

            textIndices = [0]
            titleIndices = text.chars
                .each_with_index
                .select{|char, index| char == "=" }
                .map{|pair| pair.last}

            loopRange = 0 ... (titleIndices.count/4)
            # Set index
            loopRange.each do |iteration|
                textIndices.push(titleIndices[iteration * 4] - 1)
                textIndices.push(titleIndices[(iteration * 4) + 3] + 1)
                if iteration == (titleIndices.count/4)
                    textIndices.push(text.length)
                end
            end

            titleData = ["Introducción"]
            textData = []
            #Obtain data
            loopRange.each do |iteration|
                titleData.push(text[(titleIndices[iteration * 4]) + 3 .. (titleIndices[(iteration * 4) + 3]) - 3])
                textData.push(text[textIndices[iteration * 2] .. textIndices[(iteration * 2) + 1]].strip)
            end

            createRange = 0 ... (titleData.count-1)

            createRange.each do |iteration|
                contentSet.push({
                    :wikipedia_id => row[:wikipedia_id],
                    :title => titleData[iteration],
                    :content => textData[iteration]
                })
            end

        end

        OperationalLog.create(source: "jobs/import_data", event: "import_data - category set", comment: "Number of sections: " + contentSet.count.to_s)
        
        return originSet, categorySet, contentSet


    end

    def self.loadData(origin, category, content, name, language, initial_latitude, final_latitude, initial_longitude, final_longitude)
        
        import = Import.create(
            :name => name,
            :initial_latitude => initial_latitude,
            :final_latitude => final_latitude,
            :initial_longitude => initial_longitude,
            :final_longitude => final_longitude,
            :language => language
        )

        origin.each do |point|
            
            importPoint = ImportPoint.create(
                :imports_id => import.id,
                :wikipedia_id => point[:wikipedia_id],
                :wikibase_id => point[:wikibase_id],
                :title => point[:title],
                :latitude => point[:latitude],
                :longitude => point[:longitude],
            )

            category.each do |category|
                if category[:wikipedia_id] == point[:wikipedia_id]
                    ImportThematicPoint.create(
                        :import_points_id => importPoint.id,
                        :wikibase_id => category[:category_id],
                        :name => category[:category_name]
                    )
                end
            end
            
            content.each do |content|
                if content[:wikipedia_id] == point[:wikipedia_id]
                    ImportDetail.create(
                        :import_points_id => importPoint.id,
                        :type => "",
                        :title => content[:title],
                        :content => content[:content]
                    )
                end
            end
            
        end

    end

end