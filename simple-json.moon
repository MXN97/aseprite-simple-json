-- Initial setup and check
sprite = app.activeSprite

return app.alert('There is no active sprite!') if not sprite

vertical = 'vertical'
horizontal = 'horizontal'

-- Splits a given full file path into its path, file (without extension) and the
-- extension (without the preceding .)
-- Params:
--      path - The path of a given file
-- Returns: a tuple containing the path, the filename (without extension) and
--          the extension
split_filepath = (path) ->
    string.match(path, '(.-)([^\\]-)%.(.+)$')


-- Extracts the relevant data from a single frame
-- Params:
--      frame - The current Frame
--      alignment - Flag if the frames are aligned vertically or horizontally.
--                  Can be 'vertically' or 'horizontally'
--      last_x - Optional. The x coordinate of the last frame processed
--      last_y - Optional. The y coordinate of the last frame processed
-- Returns: a tuple containing a hash table containing the x coordinate, 
--          y coordinate, width and height AND the number of values (bandaid
--          solution)
get_frame_data = (frame, alignment, last_x = 0, last_y = 0) ->
    local x, y

    sprite = frame.sprite
    width = sprite.width
    height = sprite.height

    switch alignment
        when vertical
            x = last_x + (frame.frameNumber - 1) * width
            y = last_y
        when horizontal
            x = last_x
            y = last_y + (frame.frameNumber - 1) * height
        else
            error "get_frame_data error: #{alignment}"

    {:x, :y, :width, :height}, 4
    

-- Formats the trailing comma for Json lines. It is either omitted when being
-- the last line/item or appended if not
-- Params:
--      index - Current index of whatever collection you are currently iterating
--      max - The last index of said collection
-- Returns: Either a newline if it is the last item, otherwise a comma plus a 
--          newline
format_trailing_comma = (index, max) ->
    return "\n" if index == max else ",\n"


-- Creates a json file containing the strip information
-- Params:
--      alignment - Flag if the frames are aligned vertically or horizontally.
--                  Can be 'vertically' or 'horizontally'
export_json = (alignment) ->
    path, filename, ext = split_filepath(sprite.filename)

    with file = io.open("#{path .. filename}.json", 'w')
        \write('{\n')

        last_x = nil
        last_y = nil

        for i, tag in ipairs sprite.tags
            \write("\t\"#{tag.name}\": [\n")

            frame = tag.fromFrame
            last_frame = tag.toFrame

            while true
                \write('\t\t{\n')
                frame_data, number_of_values = get_frame_data(
                    frame, 
                    alignment, 
                    last_x, 
                    last_y
                )

                index = 1

                for key, value in pairs frame_data
                    \write("\t\t\t\"#{key}\": #{value}")
                    \write(format_trailing_comma(index, number_of_values))
                    index += 1

                last_x = frame_data.last_x
                last_y = frame_data.last_y

                \write('\t\t}')
                \write(format_trailing_comma(
                        frame.frameNumber, 
                        last_frame.frameNumber
                    )
                )

                break if frame.frameNumber == last_frame.frameNumber
                
                frame = frame.next
            
            \write('\t]', format_trailing_comma(i, #sprite.tags))
        
        \write('}')
        \close!


-- Creates a dialog window to let the user decide the method of aligning the
-- frames (either vertically or horizontally) and start the script when pressing
-- the submit button
dialog = () ->
    with dlg = Dialog('Simple Json')
        \combobox({
            id: 'alignment',
            label: 'Alignment:',
            options: { vertical, horizontal }
        })
        \newrow!
        \button({ 
            id: 'submit', 
            text: 'Create Json',
            onclick: () -> \close!
        })
        \show({ wait: false })

        .bounds = Rectangle(250, 500, .bounds.width, .bounds.height)

        export_json(.data.alignment)


-- Initialisation
init = () ->
    dialog!


-- Initiate the script
init!
