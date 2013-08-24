module Handler.Home where

import Import

getHomeR :: Handler Html
getHomeR = do user <- lookupSession "user"
              case user of
                   Nothing -> do setUltDestCurrent
                                 sendFile "text/html" "static/api.html"
                   Just user -> do redirect SessionR
