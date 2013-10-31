##
# Copyright (c) 2013 Andrea Bernardini.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

from rsstoebook.OPMLData import OPMLReader
from rsstoebook.RSSData import RSSManager
from rsstoebook.RSSData import FeedManager
from rsstoebook.RSSData import DownloadedFeed
from rsstoebook.EPubData import EPubGenerator
from rsstoebook.PDFData import PDFGenerator
from rsstoebook.ArticleData import ArticleExtractor
from bottle import Bottle, post, request, static_file, run, template
from template import webr1, webr2, webr3
from time import time
from datetime import datetime
import os, logging
import os.path as op

version = '0.0.1'
np = Bottle()
web_reader_path = op.join(op.dirname(op.abspath(__file__)), 'web-reader')

logging.getLogger('').handlers = []

logging.basicConfig(
    filename = "test.log",
    filemode="w",
    level = logging.DEBUG)
logging.debug('Logging enabled')

@np.post('/rss/<format:re:epub|pdf>')
def rss(format):
    print request.json[u'links']
    feeds_urls = [(l[u'link'], l[u'date']) for l in request.json[u'links']]
    feeds = RSSManager(feeds_urls).download_feeds()
    down_feeds = FeedManager(feeds).get_downloaded_feeds()
    return output(format, down_feeds)

@np.post('/page/<format:re:epub|pdf>')
def page(format):
    items = [{'link': str(l[u'link'])} for l in request.json[u'links']]
    print items
    articles = []
    for item in items:
        articles.append(ArticleExtractor().get_article_from_item(item))
    df = DownloadedFeed('', '', articles)
    down_feeds = [df]
    return output(format, down_feeds)

@np.get('/pdf/<filename:path>')
def pdf(filename):
    return static_file(filename, root='/tmp', mimetype='application/pdf')

@np.get('/epub/<filename:path>')
def pdf(filename):
    return static_file(filename, root='/tmp', mimetype='application/epub+zip')

@np.get('/static/<filename:path>')
def send_static(filename):
    return static_file(filename, root=web_reader_path)

@np.get('/webreader/images/<filename:path>')
def images(filename):
    return static_file(filename, root = web_reader_path + '/images')

@np.get('/webreader/<filename:path>')
def webreader(filename):
    fname = filename.split('.')[0]
    if not os.path.exists(web_reader_path + '/' + fname):
        os.system("cd " + web_reader_path + '/' + "data" + " && " +
                  "bash " + web_reader_path + '/' + "data" + '/' + "extract_epub" + " /tmp/" + filename)
    return webr1 + '\'/static/' + "data/" + fname + '\'' + webr2 + filename + webr3

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

