util = require 'util'

class PDFCell
    constructor: (@document, @content, options = {})->
        @padding = options.padding ? [5, 5, 5, 5]
        @borderColor = options.borderColor ? ['#000', '#000', '#000', '#000']
        @borderWidth = options.borderWidth ? [1, 1, 1, 1]
        @borderStyle = options.borderStyle ? ['solid', 'solid', 'solid', 'solid']
        @fillColor = options.fillColor

    setWidth: (value) ->
        @width = value

    getWidth: ->
        if @width?
            @width
        else
            @getContentWidth() + @padding[1] + @padding[3]

    setMinWidth: (value) ->
        @minWidth = value

    getMinWidth: ->
        if @minWidth?
            @minWidth
        else
            @padding[1] + @padding[3]

    setMaxWidth: (value) ->
        @maxWidth = value

    getMaxWidth: ->
        if @maxWidth?
            @maxWidth
        else
            @document.bounds.width

    getContentWidth: ->
        if @width?
            @width - @padding[1] - @padding[3]
        else
            @getNaturalContentWidth()

    getNaturalContentWidth: ->
        throw new Error("PDFCell: getNaturalContentWidth() not implemented")

    setHeight: (value) ->
        @height = value

    getHeight: ->
        if @height?
            @height
        else
            @getContentHeight() + @padding[0] + @padding[2]

    getMaxHeight: ->
        @document.bounds.height

    getContentHeight: ->
        if @height?
            @height - @padding[0] - @padding[2]
        else
            @getNaturalContentHeight()

    getNaturalContentHeight: ->
        throw new Error("PDFCell: getNaturalContentHeight() not implemented")

    draw: (x, y) ->
        @_drawBackground(x, y)
        @_drawBorders(x, y)
        @_drawContent(x, y)
        return this

    _drawBackground: (x, y) ->
        if @fillColor?
            @document.rect(x, y, @getWidth(), @getHeight())
            @document.fill(@fillColor)

    _drawBorders: (x, y) ->
        width = @getWidth()
        height = @getHeight()

        if @borderWidth[0] or @borderWidth[1] or @borderWidth[2] or @borderWidth[3]
            @document.lineCap('square')
            @document.lineJoin('miter')
        if @borderWidth[0]
            @document.moveTo(x, y)
            @document.lineWidth(@borderWidth[0])
            @document.lineTo(x + width, y)
            @document.dash(@borderWidth[0] * 4, space: @borderWidth[0] * 2) if @borderStyle[0] == 'dash'
            @document.stroke(@borderColor[0])
            @document.undash()
        if @borderWidth[1]
            @document.moveTo(x + width, y)
            @document.lineWidth(@borderWidth[1])
            @document.lineTo(x + width, y + height)
            @document.dash(@borderWidth[1] * 4, space: @borderWidth[1] * 2) if @borderStyle[1] == 'dash'
            @document.stroke(@borderColor[1])
            @document.undash()
        if @borderWidth[2]
            @document.moveTo(x, y + height)
            @document.lineWidth(@borderWidth[1])
            @document.lineTo(x + width, y + height)
            @document.dash(@borderWidth[2] * 4, space: @borderWidth[2] * 2) if @borderStyle[2] == 'dash'
            @document.stroke(@borderColor[2])
            @document.undash()
        if @borderWidth[3]
            @document.moveTo(x, y)
            @document.lineWidth(@borderWidth[1])
            @document.lineTo(x, y + height)
            @document.dash(@borderWidth[3] * 4, space: @borderWidth[3] * 2) if @borderStyle[3] == 'dash'
            @document.stroke(@borderColor[3])
            @document.undash()

    _drawContent: ->
        throw new Error("PDFCell: drawContent() not implemented")

module.exports = PDFCell