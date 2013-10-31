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

module Handler.Feed where

import           Import
import           Data.Aeson.Types
import           GHC.Generics
import           Network.HTTP.Types.Status
import           Data.Time

data FeedArray = FeedArray
     { feeds :: [Feed]
     } deriving (Show, Generic)

instance ToJSON Feed
instance ToJSON FeedArray

getFeedR :: Text -> Handler Value
getFeedR stk = do
  session <- runDB $ selectFirst [SessionToken ==. stk] []
  case session of
    Nothing -> sendFail
    Just (Entity _ (Session exp user _))
        -> do now <- lift getNow
              if exp > now then
                 do elinks <- runDB $ selectList [FeedUser ==. user] []
                    returnJson $ FeedArray [x | (Entity _ x) <- elinks]
               else do
                 sendFail

sendFail :: Handler Value
sendFail = sendResponseStatus status400 emptyObject

getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now