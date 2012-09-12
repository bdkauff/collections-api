fs = require 'fs'
Browser = require 'zombie'
zombie = new Browser loadCSS: false, runScripts: false
jsdom = require 'jsdom'
jquery = require 'jquery'
debug = true

base = 'http://www.metmuseum.org/Collections/search-the-collections/'

scrape_object = (id) ->
  path = "objects/#{id}.json"

  return if not debug and fs.existsSync(path) and fs.statSync(path)?.size > 0

  zombie.visit base+id, (e, browser, status) ->
    console.log status if status is not 200
    console.log e if e?
    console.log "Scraping #{id}"

    jsdom.env
      html: browser.html
      src: [ jquery ]
      done: (e, window) ->
        _$ = (e) -> window.$ e
        object = {}
        arrify  = (str) -> str.split /\r\n/
        remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
        remove_null = (arr) -> arr.filter (e) -> e.length
        flatten = (arr) -> if arr.length is 1 then arr[0] else arr
        process = (str) -> flatten remove_null remove_nums arrify str
        object.id = +id
        # grab the uri for the image, if there is one
        object.image = _$('a[name="art-object-fullscreen"] > img').attr('src')
        object.image = null unless /^http/.test object.image
        # grab each definition and put them in their own map
        object[process _$(_$('dt')[i]).text()] = process _$(v).text() for v,i in _$('dd')
        # make an array of related artwork ids
        object['related-artworks'] = (+(_$(a).attr('href').match(/[0-9]+/g)[0]) for a in _$('.object-info a'))

      fs.writeFileSync path, JSON.stringify object

# read pages that are non-zero
fs.readdir './ids', (e, pages) ->
  for page in pages
    for id in require "./ids/#{page}"
      scrape_object id