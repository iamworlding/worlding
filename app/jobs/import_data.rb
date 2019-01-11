class ImportData
    
    @queue = :import_data

    def self.perform(name, zones, language, initial_latitude, final_latitude, initial_longitude, final_longitude)

      puts ""
      puts "  --- Start executing Import Data Job => " + Time.new.inspect + " ---"
      puts ""
      puts "      >> Name: " + name
      puts "      >> Language: " + language
      puts ""

      puts "      || ETL execution ||"
      # Log starting
      OperationalLog.create(source: "jobs/import_data", event: "Start", 
        comment: "Name: " + name + 
            " | Language: " + language + 
            " | Initial Latitude: " + initial_latitude.to_s + 
            " | Final Latitude: " + final_latitude.to_s + 
            " | Initial Longitude: " + initial_longitude.to_s + 
            " | Final Latitude: " + final_longitude.to_s
                )

      # Get area data set
      puts "      -> Extract"
      origin, category, photo, content = extractData(language, zones, initial_latitude, final_latitude, initial_longitude, final_longitude)

      puts "      -> Load"
      loadOrigin, loadCategory, loadPhoto, loadContent = loadData(origin, category, photo, content, name, language, initial_latitude, final_latitude, initial_longitude, final_longitude)

      puts "      -> Validate"
      logImport(origin, category, photo, content, loadOrigin, loadCategory, loadPhoto, loadContent)

      # Log ending
      OperationalLog.create(source: "jobs/import_data", event: "End") 

      puts ""
      puts "  --- End executing LoadPoint Job => " + Time.new.inspect + " ---"
      puts ""

    end

    def self.extractData(language, zone, initial_latitude, final_latitude, initial_longitude, final_longitude)
    
        originSet = [] # Contains every article in the Area
        categorySet = [] # Find wikibase categories from articles
        photoSet = [] # Find wikipedia articles photos urls
        contentSet = [] # Get content from articles

        # Calculate area zones
        zones = []
        
        puts "          |_> Calculate zones"
        if zone

            increment = 0.005
            
            # Calculate steps number for latitude and longitude
            # -> Latitude and longitude with dos decimal number: 40.56 -> 40.62

            initial_latitude > final_latitude ? latitudeSteps = ((initial_latitude - final_latitude) / increment).to_f.ceil : latitudeSteps = ((final_latitude - initial_latitude) / increment).to_f.ceil
            initial_longitude > final_longitude ? longitudeSteps = ((initial_longitude - final_longitude) / increment).to_f.ceil : longitudeSteps = ((final_longitude - initial_longitude) / increment).to_f.ceil

            initialStepLatitude = initial_latitude
            initialStepLongitude = initial_longitude

            (0...latitudeSteps + 1).each do |row|
                (0...longitudeSteps).each do |column|

                    zones.push("https://" + language + ".wikipedia.org/w/api.php?format=json&action=query&list=geosearch&gslimit=500&gsbbox=" + (initialStepLatitude + increment).to_s[0,8] + "|" + initialStepLongitude.to_s[0,8] + "|" + initialStepLatitude.to_s[0,8] + "|" + (initialStepLongitude + increment).to_s[0,8]) if initial_latitude > final_latitude && initial_longitude < final_longitude
                    zones.push("https://" + language + ".wikipedia.org/w/api.php?format=json&action=query&list=geosearch&gslimit=500&gsbbox=" + (initialStepLatitude + increment).to_s[0,8] + "|" + initialStepLongitude.to_s[0,8] + "|" + initialStepLatitude.to_s[0,8] + "|" + (initialStepLongitude + increment).to_s[0,8]) if initial_latitude < final_latitude && initial_longitude > final_longitude

                    initial_longitude > final_longitude ? initialStepLongitude -= increment : initialStepLongitude += increment

                end
                initialStepLongitude = initial_longitude
                initial_latitude > final_latitude ? initialStepLatitude -= increment : initialStepLatitude += increment
            end   

        else
            zones.push("https://" + language + ".wikipedia.org/w/api.php?format=json&action=query&list=geosearch&gslimit=500&gsbbox=" + initial_latitude.to_s + "|" + initial_longitude.to_s + "|" + final_latitude.to_s + "|" + final_longitude.to_s)
        end

        OperationalLog.create(source: "jobs/import_data", event: "Number of zones", comment: "Zones number: " + zones.count.to_s)


        # Get articles inside a zone
        puts "          |_> Get articles by zones"
        zones.each do |url|

            OperationalLog.create(source: "jobs/import_data", event: "Zones URL", comment: url) 
            
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

        OperationalLog.create(source: "jobs/import_data", event: "Articles set", comment: "Number of points: " + originSet.count.to_s)
        
        # Find url photos
        puts "          |_> Find url photos"
        withoutPhoto = []
        notImportedPhoto = []
        originSet.each do |row|
             
            begin

                photoResponse = HTTParty.get("https://" + language + ".wikipedia.org/w/api.php?action=query&prop=images&format=json&pageids=" + row[:wikipedia_id].to_s, format: :plain)
                photoData = JSON.parse(photoResponse)
    
                photoData["query"]["pages"][row[:wikipedia_id].to_s]["images"].each do |photo|
                    
                    # Remove not important photos
                    if !photo["title"].include?(".svg")
                        # Changes spaces for %20 and %C3%AD
                        file = photo["title"]
                            .gsub(" ", "%20")
                            .gsub("ª", "%C2%AA")
                            .gsub("º", "%C2%BA")
                            .gsub("À", "%C3%80")
                            .gsub("Á", "%C3%81")
                            .gsub("Â", "%C3%82")
                            .gsub("Ã", "%C3%83")
                            .gsub("Ä", "%C3%84")
                            .gsub("Å", "%C3%85")
                            .gsub("Æ", "%C3%86")
                            .gsub("Ç", "%C3%87")
                            .gsub("È", "%C3%88")
                            .gsub("É", "%C3%89")
                            .gsub("Ê", "%C3%8A")
                            .gsub("Ë", "%C3%8B")
                            .gsub("Ì", "%C3%8C")
                            .gsub("Í", "%C3%8D")
                            .gsub("Î", "%C3%8E")
                            .gsub("Ï", "%C3%8F")
                            .gsub("Ð", "%C3%90")
                            .gsub("Ñ", "%C3%91")
                            .gsub("Ò", "%C3%92")
                            .gsub("Ó", "%C3%93")
                            .gsub("Ô", "%C3%94")
                            .gsub("Õ", "%C3%95")
                            .gsub("Ö", "%C3%96")
                            .gsub("×", "%C3%97")
                            .gsub("Ø", "%C3%98")
                            .gsub("Ù", "%C3%99")
                            .gsub("Ú", "%C3%9A")
                            .gsub("Û", "%C3%9B")
                            .gsub("Ü", "%C3%9C")
                            .gsub("Ý", "%C3%9D")
                            .gsub("Þ", "%C3%9E")
                            .gsub("ß", "%C3%9F")
                            .gsub("à", "%C3%A0")
                            .gsub("á", "%C3%A1")
                            .gsub("â", "%C3%A2")
                            .gsub("ã", "%C3%A3")
                            .gsub("ä", "%C3%A4")
                            .gsub("å", "%C3%A5")
                            .gsub("æ", "%C3%A6")
                            .gsub("ç", "%C3%A7")
                            .gsub("è", "%C3%A8")
                            .gsub("é", "%C3%A9")
                            .gsub("ê", "%C3%AA")
                            .gsub("ë", "%C3%AB")
                            .gsub("ì", "%C3%AC")
                            .gsub("í", "%C3%AD")
                            .gsub("î", "%C3%AE")
                            .gsub("ï", "%C3%AF")
                            .gsub("ð", "%C3%B0")
                            .gsub("ñ", "%C3%B1")
                            .gsub("ò", "%C3%B2")
                            .gsub("ó", "%C3%B3")
                            .gsub("ô", "%C3%B4")
                            .gsub("õ", "%C3%B5")
                            .gsub("ö", "%C3%B6")
                            .gsub("÷", "%C3%B7")
                            .gsub("ø", "%C3%B8")
                            .gsub("ù", "%C3%B9")
                            .gsub("ú", "%C3%BA")
                            .gsub("û", "%C3%BB")
                            .gsub("ü", "%C3%BC")
                            .gsub("ý", "%C3%BD")
                            .gsub("þ", "%C3%BE")
                            .gsub("ÿ", "%C3%BF")

                        begin
                            fileResponse = HTTParty.get("https://" + language + ".wikipedia.org/w/api.php?action=query&titles=" + file + "&prop=imageinfo&iiprop=url&format=json", format: :plain)
                            fileData = JSON.parse(fileResponse)

                            photoSet.push({
                                :wikipedia_id => row[:wikipedia_id],
                                :file_url => fileData["query"]["pages"][-1.to_s]["imageinfo"][0]["url"]
                            })
                        rescue
                            notImportedPhoto.push({
                                :wikipedia_id => row[:wikipedia_id],
                                :file_url => "https://" + language + ".wikipedia.org/w/api.php?action=query&titles=" + file + "&prop=imageinfo&iiprop=url&format=json"
                            })
                            OperationalLog.create(source: "jobs/import_data", event: "Photo url bad import", comment: "URL: " + "https://" + language + ".wikipedia.org/w/api.php?action=query&titles=" + file + "&prop=imageinfo&iiprop=url&format=json")
                        end
                        
                    end                
                end

            rescue
                withoutPhoto.push({
                    :wikipedia_id => row[:wikipedia_id],
                    :file_url => "https://" + language + ".wikipedia.org/w/api.php?action=query&prop=images&format=json&pageids=" + row[:wikipedia_id].to_s
                })
                OperationalLog.create(source: "jobs/import_data", event: "Article without photo", comment: "URL: " + "https://" + language + ".wikipedia.org/w/api.php?action=query&prop=images&format=json&pageids=" + row[:wikipedia_id].to_s)
            end

             
        end
 
        OperationalLog.create(source: "jobs/import_data", event: "Photo set", comment: "Number of photos: " + photoSet.count.to_s)
        OperationalLog.create(source: "jobs/import_data", event: "Photo set", comment: "Number of photos not imported: " + notImportedPhoto.count.to_s)
        OperationalLog.create(source: "jobs/import_data", event: "Photo set", comment: "Number of article without photo: " + withoutPhoto.count.to_s)
         

        # Find categories
        puts "          |_> Find categories"
        withoutCategory = []
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
                        withoutCategory.push({
                            :wikipedia_id => row[:wikipedia_id],
                            :wikibase_id => row[:wikibase_id],
                            :title => row[:title]
                        })
                    end
                end                
            rescue
                withoutCategory.push({
                    :wikipedia_id => row[:wikipedia_id],
                    :wikibase_id => row[:wikibase_id],
                    :title => row[:title]
                })
            end
        end

        OperationalLog.create(source: "jobs/import_data", event: "Category set", comment: "Number of thematics: " + categorySet.count.to_s)
        OperationalLog.create(source: "jobs/import_data", event: "Category set", comment: "Number of points without thematic: " + withoutCategory.count.to_s)
        

        # Find content
        puts "          |_> Find content"
        originSet.each do |row|

            textResponse = HTTParty.get("https://" + language + ".wikipedia.org/w/api.php?format=json&action=query&prop=extracts&explaintext&redirects=1&pageids=" + row[:wikipedia_id].to_s, format: :plain)
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

            titleData = ["Intro"]
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
                    :content => textData[iteration],
                    :content_length => textLength
                })
            end

        end

        OperationalLog.create(source: "jobs/import_data", event: "Content set", comment: "Number of sections: " + contentSet.count.to_s)
        
        return originSet, categorySet, photoSet, contentSet


    end



    def self.loadData(origin, category, photo, content, name, language, initial_latitude, final_latitude, initial_longitude, final_longitude)

        loadOrigin = []
        loadCategory = []
        loadPhoto = []
        loadContent = []
        
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
            loadOrigin.push(importPoint.id)

            category.each do |category|
                if category[:wikipedia_id] == point[:wikipedia_id]
                    importCategory = ImportThematicPoint.create(
                        :import_points_id => importPoint.id,
                        :wikibase_id => category[:category_id],
                        :name => category[:category_name]
                    )
                    loadCategory.push(importCategory.id)
                end
            end

            photo.each do |photo|
                if photo[:wikipedia_id] == point[:wikipedia_id]
                    importPhoto = ImportPhoto.create(
                        :import_points_id => importPoint.id,
                        :file_url => photo[:file_url]
                    )
                    loadPhoto.push(importPhoto.id)
                end
            end
            
            content.each do |content|
                if content[:wikipedia_id] == point[:wikipedia_id]
                    importContent = ImportTextContent.create(
                        :import_points_id => importPoint.id,
                        :title => content[:title],
                        :content => content[:content],
                        :content_length => content[:content_length],                        
                    )
                    loadContent.push(importContent.id)
                end
            end
            
        end

        return loadOrigin, loadCategory, loadPhoto, loadContent

    end



    def self.logImport(origin, category, photo, content, loadOrigin, loadCategory, loadPhoto, loadContent)

        if origin.count > 0
            if origin.count == loadOrigin.count
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Origin: OK")
                puts "          >> Origin: OK"
            else
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Origin: KO")
                puts "          >> Origin: KO"
            end

            if category.count == loadCategory.count
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Category: OK")
                puts "          >> Category: OK"
            else
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Category: KO")
                puts "          >> Category: KO"
            end

            if photo.count == loadPhoto.count
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Photo: OK")
                puts "          >> Photo: OK"
            else
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Photo: KO")
                puts "          >> Photo: KO"
            end

            if content.count == loadContent.count
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Content: OK")
                puts "          >> Content: OK"
            else
                OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "Content: KO")
                puts "          >> Content: KO"
            end
        else
            OperationalLog.create(source: "jobs/import_data", event: "Results", comment: "No points extracted")
            puts "          >> No points extracted"
        end



    end

end