#console.time 'globals' # 14% (700ms)
fs = require 'fs'
Browser = require 'zombie'
zombie = new Browser loadCSS: false, runScripts: false
jsdom = require 'jsdom'
jquery = fs.readFileSync('./jquery.min.js').toString()
debug = true
base = 'http://www.metmuseum.org/Collections/search-the-collections/'
#console.timeEnd 'globals'

scrape_object = (id) ->
  #console.time "visit #{id}"
  path = "objects/#{id}.json"
  zombie.visit base+id, (e, browser, status) ->
    console.log status if status is not 200
    console.log e if e?
    #console.timeEnd "visit #{id}"
    #console.time "process #{id}"
    jsdom.env
      html: browser.html()
      src: [ jquery ]
      done: (e, window) ->
        # console.time 'processing' # 10% (50ms)
        $ = window.$
        object = {}
        arrify  = (str) -> str.split /\r\n/
        trim = (arr) -> str.trim() for str in arr
        remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
        remove_null = (arr) -> arr.filter (e) -> e.length
        flatten = (arr) -> if arr.length is 1 then arr[0] else arr
        process = (str) -> flatten remove_null remove_nums arrify str
        object.id = +id
        # grab the gallery id if it exists
        object['gallery-id'] = +$('.gallery-id a').text().match(/[0-9]+/g)[0] or null
        # grab the uri for the image, if there is one
        object.image = $('a[name="art-object-fullscreen"] > img').attr('src')
        object.image = null unless /^http/.test object.image
        # grab each definition and put them in their own map
        object[process $($('dt')[i]).text()] = process $(v).text() for v,i in $('dd')
        # make an array of related artwork ids
        object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.object-info a'))
        #console.timeEnd 'processing'
        $('.promo-accordion > li').each (i, e) ->
          category = process $(e).find('.category').text()
          content = $(e).find('.accordion-inner > p').text().trim()
          switch category
            when 'Description' then object[category] = content
            when 'Provenance' then object[category] = trim remove_null content.split(';')

        fs.writeFileSync path, JSON.stringify object
        #console.timeEnd "process #{id}"
        
for arg in process.argv[2..]
  scrape_object id for id in require arg