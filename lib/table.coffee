PDFTextCell = require './table/text-cell'
util        = require 'util'

# Ensure an index is valid for given array
validIndex = (arr, i, incl = false) ->
    unless i >= 0 and i < arr.length or (incl and i == arr.length)
        throw new Error "Invalid index"

# Sum the values of an array
sumArray = (arr) ->
    sum = 0
    sum += value for value in arr
    sum

# Options:
#   columnsWidths: Array
#   cellStyle: {
#     padding: Array,
#     borderColor: Array,
#     borderWidth: Array,
#     backgroundColor,
#     font: String,
#     fontSize: Number
#   }
#   width: Number
#   cellStyleFunc: Function
class PDFTable
    constructor: (@document, data, options = {}) ->
        @rows = []
        @width = options.width or 0
        @columnWidths = options.columnWidths
        @header = if options.header then true else false
        @cellStyle = options.cellStyle or {}
        @cellStyleFunc = options.cellStyleFunc
        @addRows(data)

    # Append rows to table
    addRows: (rows) ->
        @insertRows(@rows.length, rows)

    # Insert rows at the given row index
    insertRows: (index, rows) ->
        validIndex(@rows, index, true)
        for row, i in rows
            newRow = []
            for content, j in row
                if typeof content == 'string'
                    cell = new PDFTextCell(@document, content, @cellStyle)
                else
                    throw new Error("PDFTable: Cell content is of unsupported type")
                cell.width = @columnWidths[j] if @columnWidths?
                newRow[j] = cell
                @cellStyleFunc.call(null, i, j, cell) if typeof @cellStyleFunc == 'function'
            @rows.splice(index + i, 0, newRow)
        @_calculateColumnDimensions(index, rows.length)
        @_applyColumnDimensions()

    # Get the row at the given row index
    getRow: (index) ->
        validIndex(@rows, index)
        @rows[index]

    # Get the cell at the given row and column indices
    getCell: (rowIndex, colIndex) ->
        validIndex(@rows, rowIndex)
        validIndex(@rows[rowIndex], colIndex)
        @rows[rowIndex][colIndex]

    # Render table to document
    # O(3NM)
    draw: ->
        x = startX = @document.x
        y = @document.y
        # @_normalize()
        columnWidths = @_getColumnWidths()
        @_applyColumnDimensions()
        for row, i in @rows
            x = startX
            for cell, j in row
                cell.draw(x, y)
                x += columnWidths[j]
            y += @rowHeight[i]
        return this

    # Aggregate columns and perform an operation on the value of a given
    # property or result of a given method.
    # Supported operations: sum, avg, max, min
    # O(N 2M)
    aggregateColumns: (field, operation) ->
        @_aggregate(false, field, operation)

    # Aggregate rows and perform an operation on the value of a given
    # property or result of a given method.
    # Supported operations: sum, avg, max, min
    # O(N 2M)
    aggregateRows: (field, operation) ->
        @_aggregate(true, field, operation)

    # Perform aggregation and summary operation on rows or columns.
    # For internal use
    _aggregate: (rowMode, field, operation) ->
        values = []
        for row, i in @rows
            for cell, j in row
                value = if typeof cell[field] == 'function' then cell[field]() else cell[field]
                index = if rowMode then i else j
                values[index] = Math.max(value, values[index] or 0)
        result = if operation == 'min' then null else 0
        for value in values
            switch operation
                when 'sum', 'avg'
                    result += value
                when 'max'
                    result = Math.max(result, value)
                when 'min'
                    result = result ? value
                    result = Math.min(result, value)
        switch operation
            when 'sum', 'min', 'max' then result
            when 'avg' then result / values.length
            else
                throw new Error("Table: unsupported operation '" + operation + "'")

    # Get an array of column widths taking into account constraints.
    # Throws error if content is wider than table or if table is wider than content.
    _getColumnWidths: ->
        if @width - @minWidth < -1e-9
            throw new Error("Table width smaller than its content's min width")
        if @width - @maxWidth > 1e-9
            throw new Error("Table width larger than its content's max width " + @width + ", " + @maxWidth)
        if @width - @naturalWidth < -1e-9
            f = parseFloat(@width - @minWidth) / (@naturalWidth - @minWidth)
            len = @rows[0].length
            return [0...len].map (i) =>
                nat = @naturalColumnWidth[i]
                min = @minColumnWidth[i]
                value = (f * (nat - min)) + min
                value
        else if @width - @naturalWidth > 1e-9
            f = parseFloat(@width - @naturalWidth) / (@maxWidth - @width)
            return [0...len].map (i) =>
                nat = @naturalColumnWidth[i]
                max = @maxColumnWidth[i]
                value = (f * (max - nat)) + nat
                value
        else
            @naturalColumnWidth

    # Calculate min, max and natural widths for all columns
    # For internal use
    # O(N 4M)
    _calculateColumnDimensions: (offset, length) ->
        unless offset? and offset > 0
            offset = 0
        unless length? and length > 0 and length <= @rows.length
            length = @rows.length
        rows = @rows.slice(offset, offset + length)
        @minColumnWidth = @minColumnWidth ? []
        @maxColumnWidth = @maxColumnWidth ? []
        @naturalColumnWidth = @naturalColumnWidth ? []
        @rowHeight = @rowHeight ? []
        for row, i in rows
            for cell, j in row
                @minColumnWidth[j] = Math.max(cell.getMinWidth(), @minColumnWidth[j] or 0)
                @maxColumnWidth[j] = Math.min(cell.getMaxWidth(), @maxColumnWidth[j] or @document.bounds.width)
                @naturalColumnWidth[j] = Math.max(cell.getWidth(), @naturalColumnWidth[j] or 0)
                @rowHeight[i] = Math.max(cell.getHeight(), @rowHeight[i] or 0)
        @minWidth = sumArray(@minColumnWidth)
        @maxWidth = sumArray(@maxColumnWidth)
        @naturalWidth = sumArray(@naturalColumnWidth)
        @width = Math.min(@naturalWidth, @document.bounds.width)

    # O(NM)
    _applyColumnDimensions: ->
        columnWidths = @_getColumnWidths()
        for row, i in @rows
            for width, j in columnWidths
                @rows[i][j].setWidth width
                @rows[i][j].setHeight @rowHeight[i]

module.exports = PDFTable