NewsPrint
=========

A web service that transforms web contents to printable or e-reader format

Copyright: 2013 Andrea Bernardini

License: Apache 2.0


The whole system is composed by four components:

* Account Manager web service : this component exports a REST public interface, providing functions to
create user sessions and to store and manage user data. The service is intended to completely hide the
database technology used to store data. (Written in Haskel using the Yesod framework)

* PDF/EPUB generator web service : this service can be used to create a readable document starting from
a list of web page URLs or a list of RSS Feed URLs. The generator takes care of downloading all the
relevant content from the provided URLs and create a le that can be easily printed or read on an Ebook
reader. (Written in Python using the Bottle framework and [rsstoebook](https://github.com/andrebask/rsstoebook))

* Web-based user interface : this component is at the same time a web site and a REST client. It shows
to the user the graphical interface and uses the Account Manager web service to store and retrieve data
related to a specic session. It also send data to the PDF/EPUB generator when requested by the user. (Written in Haskel using the Yesod framework)

* Bookmarklet : A javascript function that send a web page URL to the NewsPrint server when requested
by the user. This is a component easily installable in the browser as a bookmark.
