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

module Handler.Submit where

import Data.Aeson.Types
import Data.Time
import System.Locale
import Data.Text hiding (tail, head)
import Prelude (head, tail)
import Import hiding (catch)
import Network.HTTP.Types.Status
import GHC.Generics

data JSONSubmit = JSONSubmit {
       title :: Text
     , url :: Text
     , content :: Text
     } deriving (Show, Generic)

instance FromJSON JSONSubmit

-- Retreive the submitted data from the user
postSubmitR :: Text -> Handler ()
postSubmitR token = do
  (result :: Result Value) <- parseJsonBody
  case result of
    Success v
        -> case v of
             Object o
                 -> do (jsmt :: Result JSONSubmit)
                           <- return (fromJSON v)
                       user <- iouser
                       case jsmt of
                         Success (JSONSubmit t u c) ->
                             tryInsert t u user c
                         Error e -> sendFail
             otherwise -> sendFail
    Error e
        -> sendFail
 where iouser = verifySession token

verifySession :: Text -> Handler Text
verifySession token = do
  session <- runDB $ selectFirst [SessionToken ==. token] []
  case session of
    Nothing -> sendResponseStatus status400 ("" :: Text)
    Just (Entity _ (Session exp user _))
        -> do now <- lift getNow
              if exp > now then
                  return user
               else do
                 sendResponseStatus status400 ("" :: Text)


tryInsert :: Text -> Text -> Text -> Text -> Handler ()
tryInsert title url user content = do saved <- lift getNow
                                      case content of
                                        "html" -> do _ <- runDB $ insert $ Link title url site user saved
                                                     sendResponse ()
                                        "rss"  -> do _ <- runDB $ insert $ Feed title url site read user
                                                     sendResponse ()
                                        _      -> sendFail
    where site = head $ splitOn "/" $ head $ tail $ splitOn "//" url
          read = readTime defaultTimeLocale "%F" "1970-01-01"

getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now

sendFail :: Handler ()
sendFail = sendResponseStatus status400 ()