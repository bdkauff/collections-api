fs = require 'fs'
Browser = require 'zombie'
zombie = new Browser loadCSS: false, runScripts: false

# Scrape the mobile site (sc_device=mobile) since aredridel/html5 hates the http://w.sharethis.com/button/buttons.js script
# To scrape the non-mobile site, make sure to instantiate the Browser object with runScripts: false
base = 'http://www.metmuseum.org/collections/search-the-collections?sc_device=mobile&ft=*&whento=2050&whenfunc=before&rpp=60&pg='

scrape_page = (page) ->
  path = "ids/#{page}.json"

  # skip up to the last file that exists
  while fs.existsSync path
    page++
    path = "ids/#{page}.json"

  page-- if page > 1

  zombie.visit base+page, (e, browser, status) ->
    console.log status if status is not 200
    console.log e if e?
    console.log "Scraping #{page}"

    links = browser.document.querySelectorAll '.image-content a'
    links = links.map (link) -> /([0-9]+)/.exec(link.href)[0]
    fs.writeFileSync path, JSON.stringify links

    scrape_page ++page if ~browser.document.querySelectorAll('.next').length

scrape_page 1