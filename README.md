⚠️ This project is deprecated. Touchstone gyms have moved to using a [Kaya](https://kayaclimb.com/) widget on their sites to display new routes. This widget is loaded with javascript after the page loads so can't be accessed with basic html webscraping.

---

# bouldering_notifications
This is a small ruby app that checks the websites of three Bay Area climbing gyms ([Great Western Power Co.](https://touchstoneclimbing.com/gwpower-co/), [Berkeley Ironworks](https://touchstoneclimbing.com/ironworks/), and [Dogpatch Boulders](https://touchstoneclimbing.com/dogpatch-boulders/)) daily and sends a push notification to my phone if any of them have updated their bouldering problems.

- Run daily using [Heroku Scheduler](https://elements.heroku.com/addons/scheduler)
- Scrapes Touchstone websites with [Nokogiri](https://nokogiri.org/) and stores the result in a tiny persisted [Redis](https://redis.io/) "database"
- If different from the last run, a notification is sent using [Pushover](https://pushover.net/)

## License

[MIT](LICENSE)
