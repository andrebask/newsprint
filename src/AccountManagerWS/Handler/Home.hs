module Handler.Home where

import Import

getHomeR :: Handler Html
getHomeR = sendFile "text/html" "static/api.html"
