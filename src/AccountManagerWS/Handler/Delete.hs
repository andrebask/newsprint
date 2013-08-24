module Handler.Delete where

import Data.ByteString hiding (isInfixOf)
import Data.Aeson.Types
import Data.Time
import Import hiding (catch)
import Network.HTTP.Types.Status
import GHC.Generics
import Model (User, Link, Feed)

data JSONDelUser = JSONDelUser {
      username :: Text
     } deriving (Show, Generic)

data JSONDelLink = JSONDelLink {
      linkurl :: Text
     } deriving (Show, Generic)

data JSONDelFeed = JSONDelFeed {
      feedurl :: Text
     } deriving (Show, Generic)

instance FromJSON JSONDelUser
instance FromJSON JSONDelLink
instance FromJSON JSONDelFeed

-- Retreive the submitted data from the user

postDeleteR :: Text -> Text -> Handler ()
postDeleteR entity token
    | entity == "user" = do { u <- user; handleUserDel u }
    | entity == "link" = do { u <- user; handleLinkDel u }
    | entity == "feed" = do { u <- user; handleFeedDel u }
    | otherwise      = sendFail
    where user = verifySession token


verifySession :: Text -> Handler Text
verifySession token = do
  session <- runDB $ selectFirst [SessionToken ==. token] []
  let sendFail = sendResponseStatus status400 ()
  case session of
    Nothing -> sendFail
    Just (Entity _ (Session exp user _))
        -> do now <- lift getNow
              if exp > now then
                  return user
               else do
                 sendFail

handleUserDel :: Text -> Handler ()
handleUserDel  user = do
  (result :: Result Value) <- parseJsonBody
  case result of
    Success v
        -> case v of
             Object o -> do (delUser :: Result JSONDelUser)
                                <- return (fromJSON v)
                            case delUser of
                              Success (JSONDelUser u)
                                  -> if u == user then do
                                        tryUserDelete u
                                      else do
                                        sendFail
                              Error e -> sendFail
             otherwise -> sendFail
    Error e
        -> sendFail

tryUserDelete :: Text -> Handler ()
tryUserDelete user = do runDB $ deleteWhere [UserUsername ==. user]
                        runDB $ deleteWhere [LinkUser ==. user]
                        runDB $ deleteWhere [FeedUser ==. user]
                        runDB $ deleteWhere [SessionUser ==. user]
                        sendResponse ()

handleLinkDel :: Text -> Handler ()
handleLinkDel user = do
  (result :: Result Value) <- parseJsonBody
  case result of
    Success v
        -> case v of
             Object o -> do (delUser :: Result JSONDelLink)
                                <- return (fromJSON v)
                            case delUser of
                              Success (JSONDelLink url)
                                  -> tryLinkDelete url user
                              Error e -> sendFail
             otherwise -> sendFail
    Error e
        -> sendFail




tryLinkDelete :: Text -> Text -> Handler ()
tryLinkDelete url user = do runDB $ deleteWhere ([ LinkUrl ==. url
                                                , LinkUser ==. user])
                            sendResponse ()

handleFeedDel :: Text -> Handler ()
handleFeedDel  user = do
  (result :: Result Value) <- parseJsonBody
  case result of
    Success v
        -> case v of
             Object o -> do (delUser :: Result JSONDelFeed)
                                <- return (fromJSON v)
                            case delUser of
                              Success (JSONDelFeed url)
                                  -> tryFeedDelete url user
                              Error e -> sendFail
             otherwise -> sendFail
    Error e
        -> sendFail

tryFeedDelete :: Text -> Text -> Handler ()
tryFeedDelete url user = do runDB $ deleteWhere ([ FeedUrl ==. url
                                                , FeedUser ==. user])
                            sendResponse ()

sendFail :: Handler ()
sendFail = sendResponseStatus status400 ()

getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now