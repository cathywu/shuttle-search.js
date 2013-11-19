# shuttle-search.js

shuttle-search.js is a webapp written in CoffeeScript, SASS, and HTML5, which interfaces with dropbox.js for global data storage. The webapp is two-fold: 1) it is an easy-to-maintain visualization tool for viewing employee addresses and arbitrary shuttle routes, and 2) it is a public transit directions recommendations interface that searches for directions by incorporating both existing public transit feeds that are available to Google and (private or semi-private) shuttle feeds that are not available to Google.

## Development

1. [Create a powered_by.js app in your Dropbox](https://dl-web.dropbox.com/spa/pjlfdak1tmznswp/powered_by.js/public/index.html).
1. [Get your own API key](https://www.dropbox.com/developers/apps). Create a "full permission" App. (TODO: I would like to change this in the future, but Dropbox does not allow for shared folders within the `Apps` namespace, so we must place and access our data files outside of `Apps`.)
1. Copy the APP URL from `static web apps` to OAuth redirect URIs in the [developer console](https://www.dropbox.com/developers/apps) for your newly created app.
1. Copy the source code to `/Apps/Static Web Apps/powered_by.js` in your
   Dropbox.
1. [Create a Simple API Access key](https://cloud.google.com/console). Go to APIs & auth > APIs, and click to enable "Google Maps API v3". Go to APIs & auth > Registered apps > Register App > Web App > Browser Key. Copy the API key and replace the placeholder API key in `https://maps.googleapis.com/maps/api/js?key=GOOGLE_API_KEY&sensor=false`.

## Dependencies

The application uses the following JavaScript libraries.

* [dropbox.js](https://github.com/dropbox/dropbox-js) for Dropbox integration
* [less](http://lesscss.org/) for CSS conciseness
* [CoffeeScript](http://coffeescript.org/) for JavaScript conciseness
* [jQuery](http://jquery.com/) for cross-browser compatibitility

The icons used in the application are all from
[the noun project](http://thenounproject.com/).

The application follows a good practice of packaging its dependencies, and not
hot-linking them.
