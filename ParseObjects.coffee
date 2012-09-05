fs = require 'fs'
Browser = require 'zombie'
zombie = new Browser loadCSS: false, runScripts: false

# Scrape the mobile site (sc_device=mobile) since aredridel/html5 hates the http://w.sharethis.com/button/buttons.js script
# To scrape the non-mobile site, make sure to instantiate the Browser object with runScripts: false
base = 'http://www.metmuseum.org/Collections/search-the-collections/'

scrape_object = (id) ->
  path = "objects/#{id}.json"
  if fs.existsSync path
    if fs.statSync(path).size > 0
      return

  zombie.visit base+id, (e, browser, status) ->
    console.log status if status is not 200
    console.log e if e?
    console.log "Scraping #{page}"
    _$ = browser.document.querySelectorAll

    object = {}
    arrify  = (str) -> str.split /\r\n/
    remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
    remove_null = (arr) -> arr.filter (e) -> e.length
    flatten = (arr) -> if arr.length is 1 then arr[0] else arr
    process = (str) -> flatten remove_null remove_nums arrify str
    object.id = +id
    object.image = _$('a[name="art-object-fullscreen"] > img').src
    object.image = null unless /^http/.test object.image
    object[process _$(_$('dt')[i]).text()] = process _$(v).text() for v,i in _$('dd')
    object['related-artworks'] = (+(_$(a).attr('href').match(/[0-9]+/g)[0]) for a in _$('.object-info a'))

    fs.writeFileSync path, JSON.stringify object

# read pages that are non-zero
fs.readdir './ids', (e, pages) ->
  for page in pages
    for id in require "./ids/#{page}"
      scrape_object id