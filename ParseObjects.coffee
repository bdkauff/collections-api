nodeio = require 'node.io'
fs = require 'fs'

class ParseObjects extends nodeio.JobClass
  _arrify  = (str) -> str.split /\r\n/
  _remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
  _remove_null = (arr) -> arr.filter (e) -> e.length
  _flatten = (arr) -> if arr?.length is 1 then arr[0] else arr
  _process = (str) -> _flatten _remove_null _remove_nums _arrify str
  _trim = (arr) -> str.trim() for str in arr

  run: (id) ->
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'
    object = {}

    @getHtml base+id, (err, $) =>
      @retry() if err?

      object['id'] = +id
      object['gallery-id'] = +$('.gallery-id a').text().match(/[0-9]+/g)?[0] or null
      object['image'] = _flatten $('a[name="art-object-fullscreen"] > img')?.attr('src')?.match /(^http.*)/g
      object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.related-content-container .object-info a'))

      # add any definition lists as properties
      object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')

      # add description and provenance
      $('.promo-accordion > li').each (i, e) ->
        category = _process $(e).find('.category').text()
        content = $(e).find('.accordion-inner > p').text().trim()
        switch category
          when 'Description' then object[category] = content
          when 'Provenance' then object[category] = _trim _remove_null content.split(';')

      @emit id: id, object: object

  output: (rows) ->
    for row in rows
      fs.writeFileSync "objects/#{row.id}.json", JSON.stringify row.object, null, 2

@job = new ParseObjects {jsdom: true}