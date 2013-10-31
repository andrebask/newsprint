////
// Copyright (c) 2013 Andrea Bernardini.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////

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
