PDFTable = require '../table'

module.exports =
    table: (data, options = {}) ->
        t = new PDFTable(this, data, options)
        t.special = 'wee!'
        t.draw()
        return this