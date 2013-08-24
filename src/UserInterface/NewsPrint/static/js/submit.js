function post_to_url(path, params, method) {
    method = method || "post"; // Set method to post by default if not specified.

    // The rest of this code assumes you are not using a library.
    // It can be made less wordy if you use one.
    var form = document.createElement("form");
    form.setAttribute("method", method);
    form.setAttribute("action", path);

    for(var key in params) {
        if(params.hasOwnProperty(key)) {
            var hiddenField = document.createElement("input");
            hiddenField.setAttribute("type", "hidden");
            hiddenField.setAttribute("name", key);
            hiddenField.setAttribute("value", params[key]);

            form.appendChild(hiddenField);
         }
    }

    document.body.appendChild(form);
    form.submit();
}

try{
    var req = new XMLHttpRequest();
    req.open('GET', document.location, false);
    req.send(null);
    var header = req.getResponseHeader('content-type').toLowerCase();

    post_to_url("http://localhost:2000/submit", {title: encodeURIComponent(document.title), url: encodeURIComponent(location.href), content: header});
}catch(err){
    post_to_url("http://localhost:2000/submit", {title: encodeURIComponent(document.title), url: encodeURIComponent(location.href), content: "unknown"});
}
