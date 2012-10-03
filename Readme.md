Collections Scraper
===================

Yes, the met museum is scraping its own [collections website][1]. Did we mention there are a lot of independent teams here? Pull requests welcome.

Install
-------

    npm install

Run
---
    There are two npm scripts, `grab_ids` and `parse_ids`.
    `grab_ids` will make arrays of object ids, 60 per page, and dump them in ids/{[0-9]+}.json
    `parse_ids` will look in `ids/` and start building objects in object/{prefix}/{objectid}.json, where prefix seems to be a common prefix, perhaps a department id.
    Both of these scripts are designed so that when the get too slow or crash, kill them, restart, and they should pick up where they left off.

[1]: http://www.metmuseum.org/collections/
