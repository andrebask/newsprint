module Handler.UpdateFeed where

import Data.Aeson.Types
import Data.Time
import System.Locale
import Data.Text hiding (tail, head)
import Prelude (head, tail)
import Import hiding (catch)
import Network.HTTP.Types.Status
import GHC.Generics

data JSONUpdate = JSONUpdate {
         url :: Text
       , time :: UTCTime
     } deriving (Show, Generic)

data UpdateArray = UpdateArray {
         feeds :: [JSONUpdate]
     } deriving (Show, Generic)

instance FromJSON JSONUpdate
instance FromJSON UpdateArray

-- Retreive the submitted data from the user
postUpdateFeedR :: Text -> Handler ()
postUpdateFeedR token = do
  (result :: Result Value) <- parseJsonBody
  lift $ putStrLn $ "####################UPDATE FEED HANDLER#####################"
  case result of
    Success v
        -> case v of
             Object o
                 -> do (jsup :: Result UpdateArray)
                           <- return (fromJSON v)
                       user <- iouser
                       case jsup of
                         Success (UpdateArray f) ->
                             tryUpdate f user
                         Error e -> sendFail
             otherwise -> sendFail
    Error e
        -> sendFail
 where iouser = verifySession token

verifySession :: Text -> Handler Text
verifySession token = do
  session <- runDB $ selectFirst [SessionToken ==. token] []
  case session of
    Nothing -> sendResponseStatus status400 ("Not a valid session" :: Text)
    Just (Entity _ (Session exp user _))
        -> do now <- lift getNow
              if exp > now then
                  return user
               else do
                 sendResponseStatus status400 ("Session expired" :: Text)

tryUpdate :: [JSONUpdate] -> Text -> Handler ()
tryUpdate feeds user =
  do updateFeeds feeds user
     sendResponse ()

updateFeeds :: [JSONUpdate] -> Text -> Handler ()
updateFeeds [] user = do return ()
updateFeeds (x:xs) user =
  do _ <- case x of
            JSONUpdate url date ->
              runDB $ updateWhere [FeedUrl ==. url, FeedUser ==. user] [FeedRead =. date]
            _ -> return ()
     lift $ putStrLn $ show x
     updateFeeds xs user


getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now

sendFail :: Handler ()
sendFail = sendResponseStatus status400 ()