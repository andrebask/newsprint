----
-- Copyright (c) 2013 Andrea Bernardini.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
----

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