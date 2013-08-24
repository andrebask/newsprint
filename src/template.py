webr1 = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>NewsPrint Web Reader</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="stylesheet" href="/static/epubjs/css/epubjs.css" ></link>
    <link type="text/css" href="/static/epubjs/css/ui-lightness/jquery-ui-1.7.1.custom.css" rel="stylesheet" />

    <script type="text/javascript">

      var epub_dir = """

webr2 = """;
    </script>
    <script type="text/javascript" src="/static/epubjs/jquery-1.3.2.min.js"></script>
    <script type="text/javascript" src="/static/epubjs/jquery-ui-1.7.1.custom.min.js"></script>
    <script type="text/javascript" src="/static/epubjs/mousewheel.js"></script>
    <script type="text/javascript" src="/static/epubjs/epubjs.js"></script>

    <!-- styles needed by jScrollPane - include in your own sites -->
    <link type="text/css" href="/static/jspane/jquery.jscrollpane.css" rel="stylesheet" media="all" />
    <!-- latest jQuery direct from google's CDN -->
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
    <!-- the mousewheel plugin -->
    <script type="text/javascript" src="/static/jspane/jquery.mousewheel.js"></script>
    <!-- the jScrollPane script -->
    <script type="text/javascript" src="/static/jspane/jquery.jscrollpane.min.js"></script>

    <script type="text/javascript">
      jQuery(function($)
       {
          var settings = {
            showArrows: true,
            autoReinitialise: true
          };
          $('#toc-container').bind(
				'jsp-initialised',
				function(event, isScrollable)
				{
                                  if (isScrollable == true) {
                                    $('#toc-container').css("border-right", "none");
                                  }
				}
                              ).jScrollPane(settings);
      });
    </script>

  </head>
  <body>
    <div class="topbar">
      <img src="/static/img/book_small.png" class="logo"><span class="topbar_title">NewsPrint</span>
    </div>
    <div id="book" class="clear">
      <div id="toc-container"><ol id="toc"></ol></div>
      <h1 id="content-title" ></h1>
      <!--<div id="total-size"><div id="remaining"></div></div>-->
      <div id="content"></div>
    </div>
    <!--<div id="info">
    <p>Usage: 'n' for next page, 'p' for previous page, 'j' for next chapter, 'k' for previous chapter</p>
    <p>Current support: Firefox, Safari, IE 7. As of April 7, 2009.</p>
    <p>Resizable window, see lower-right corner. Mousewheel support to paginate forward and back.</p>
    <p>Available from <a href="http://code.google.com/p/epub-tools/source/browse/#svn/trunk/epubtools/epubjs">Google Code</a></p>
    </div>-->
  </body>
</html>"""