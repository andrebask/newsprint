from rsstoebook.OPMLData import OPMLReader
from rsstoebook.RSSData import RSSManager
from rsstoebook.RSSData import FeedManager
from rsstoebook.RSSData import DownloadedFeed
from rsstoebook.EPubData import EPubGenerator
from rsstoebook.PDFData import PDFGenerator
from rsstoebook.ArticleData import ArticleExtractor
from bottle import Bottle, post, request, static_file, run
from time import time
import os

version = '0.0.1'
np = Bottle()

@np.post('/opml/<format:re:epub|pdf>')
def opml(format):
    try:
        opml_files = save_files(request)
    except:
        return 'File extension not allowed.'
    feeds_urls = []
    for o in opml_files:
        feeds_urls + OPMLReader(o).get_feeds_urls()
    feeds = RSSManager(feeds_urls).download_feeds()
    down_feeds = FeedManager(feeds).get_downloaded_feeds()
    return static_file(output(format, down_feeds), root='/tmp')

@np.post('/rss/<format:re:epub|pdf>')
def rss(format):
    feeds_urls = [l[u'link'] for l in request.json[u'links']]
    feeds = RSSManager(feeds_urls).download_feeds()
    down_feeds = FeedManager(feeds).get_downloaded_feeds()
    return static_file(output(format, down_feeds), root='/tmp')

@np.post('/page/<format:re:epub|pdf>')
def page(format):
    print request.json
    items = [{'link': l[u'link']} for l in request.json[u'links']]
    articles = []
    for item in items:
        articles.append(ArticleExtractor().get_article_from_item(item))
    df = DownloadedFeed('', '', articles)
    down_feeds = [df]
    return static_file(output(format, down_feeds), root='/tmp')

def output(format, down_feeds):
    name = str(int(time()*1000000))
    filename = os.path.join('/tmp', name)
    if format == 'epub':
        name += '.epub'
        EPubGenerator(down_feeds).generate_epub(filename)
    elif format == 'pdf':
        name += '.pdf'
        filename += '.pdf'
        PDFGenerator(down_feeds).generate_pdf(filename)
    print name
    return name

def save_files(request):
    save_path = '/tmp'
    upload = request.files
    files = []
    for file in upload:
        files.append(file.filename)
        name, ext = os.path.splitext(file.filename)
        if ext not in ('opml'):
            raise Exception('File extension not allowed.')
    for file in upload:
        file.save(save_path)
    return files

run(np, host='localhost', port=8080, debug=True)
