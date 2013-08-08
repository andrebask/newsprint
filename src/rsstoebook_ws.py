from OPMLData import OPMLReader
from RSSData import RSSManager
from RSSData import FeedManager
from RSSData import DownloadedFeed
from EPubData import EPubGenerator
from PDFData import PDFGenerator
from ArticleData import ArticleExtractor
from bottle import Bottle, post, request, static_file
import os.join, os.path

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
    feeds_urls = request.json.links
    feeds = RSSManager(feeds_urls).download_feeds()
    down_feeds = FeedManager(feeds).get_downloaded_feeds()
    return static_file(output(format, down_feeds), root='/tmp')

@np.post('/page/<format:re:epub|pdf>')
def page(format):
    pages = request.json.links
    items = []
    for url in pages:
        items.append({'link': url})
    articles = []
    for item in items:
        articles.append(ArticleExtractor().get_article_from_item(item))
    df = DownloadedFeed('', '', articles)
    down_feeds = [df]
    return static_file(output(format, down_feeds), root='/tmp')

def output(format, down_feeds):
    name = str(int(time()*1000000))
    filename = os.join('/tmp', name)
    if format == 'epub':
        name += '.epub'
        filename += '.ebub'
        EPubGenerator(down_feeds).generate_epub(filename)
    elif format == 'pdf':
        name += '.pdf'
        filename += '.pdf'
        PDFGenerator(down_feeds).generate_pdf(filename)
    return name

def save_files(request):
    save_path = os.join('/tmp',
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

