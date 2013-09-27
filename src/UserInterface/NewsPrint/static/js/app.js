$('.button').click(function(){
   $('<div id="loading" class=loading_div><div class=loading_text>Downloading content...</div></div>').prependTo(document.body);
});

window.onbeforeunload=function(){
    var l = document.getElementById("loading");
    l.style="display: none;";
};