PDFCell = require './cell'
util    = require 'util'

class PDFTextCell extends PDFCell
    constructor: (@document, @content, options = {}) ->
        super(@document, @content, options)
        @font = options.font
        @fontColor = options.fontColor ? '#000'
        @fontSize = options.fontSize
        @align = options.align or 'left'

    getMinWidth: ->
        if @minWidth?
            @minWidth
        else
            minContentWidth = Math.min(@getNaturalContentWidth(), @_getWidthOfSingleChar())
            minContentWidth + @padding[1] + @padding[3]

    getNaturalContentWidth: ->
        Math.min(@document.widthOfString(@content), @document.bounds.width)

    getNaturalContentHeight: ->
        context = { font: @font, fontSize: @fontSize, align: @align }
        height = @document.withFontContext context, =>
            @document.heightOfString(@content, @getContentWidth())
        Math.min(height, @document.bounds.height)

    _drawContent: (x, y) ->
        width   = @getContentWidth()
        content = @content
        context = { font: @font, fontSize: @fontSize, fillColor: @fontColor }
        options = { align: @align, width: @width }
        @document.withFontContext context, =>
            # options = { width: width } # align: @align
            # Only pass width (which cuases wrapping) if text contains whitespace
            if /\s+/.test(content)
                options.width = width
            # Otherwise, split up word to and allow wrapping
            else if @document.widthOfString(content) > width
                content = @_splitWord(content, width)
                options.width = width
            # console.log 'drawing with width = ' + width + ' x = ' + x + @padding[3] + ' y = ' + y + @padding[0]
            @document.text(content, x + @padding[3], y + @padding[0], options)

    _splitWord: (string, boundWidth) ->
        context = { font: @font, fontSize: @fontSize }
        @document.withFontContext context, =>
            wordWidth = @document.widthOfString(string, @fontSize)
            return string if wordWidth <= boundWidth
            width = 0
            word = ''
            i = 0
            while i < string.length
                charWidth = @document.widthOfString(string[i], @fontSize)
                if width + charWidth < boundWidth
                    width += charWidth
                    word += string[i]
                    i++
                else
                    word += '\n'
                    width = 0
            word

    _getWidthOfSingleChar: ->
        context = { font: @font, fontSize: @fontSize }
        widthOfChar = @document.withFontContext context, => @document.widthOfString('M')
        widthOfChar

module.exports = PDFTextCell