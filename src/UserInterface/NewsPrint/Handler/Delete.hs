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

module Handler.Delete where

import Import
import Data.Aeson
import qualified System.IO.Streams as S
import Network.Http.Client
import Network.HTTP.Types.URI     (urlDecode)
import GHC.Generics
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Text.Encoding
import Data.Text
import Data.Time

data JSONDelUser = JSONDelUser {
      username :: Text
     } deriving (Show, Generic)

data JSONDelLink = JSONDelLink {
      linkurl :: Text
     } deriving (Show, Generic)

data JSONDelFeed = JSONDelFeed {
      feedurl :: Text
     } deriving (Show, Generic)

instance ToJSON JSONDelUser
instance ToJSON JSONDelLink
instance ToJSON JSONDelFeed

postDeleteR :: Handler ()
postDeleteR = do itemType <- runInputPost $ ireq hiddenField "type"
                 url <- runInputPost $ ireq hiddenField "delete"
                 u <- lookupSession "user"
                 case u of
                   Nothing -> do { setUltDestCurrent; redirect HomeR }
                   Just user
                       -> do token <- lookupSession "token"
                             let tk = case token of
                                        Nothing -> ("" :: Text)
                                        Just t -> t
                             sc <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                                         (submitItem itemType url tk)
                             case sc of
                               Just 200 -> redirect SessionR
                               Nothing  -> redirect HomeR
                               _  -> redirect HomeR

submitItem :: Text -> Text -> Text -> Connection -> IO (Maybe StatusCode)
submitItem itemType url token conn =
    do q <- buildRequest $ do
              http POST $ B.append "/delete/" $ B.append  (B.append (encodeUtf8 itemType) "/") (encodeUtf8 token)
              setContentType "application/json"
              setAccept "application/json"

       jsBS <- do case itemType of
                    "link" -> return (encode (JSONDelLink { linkurl = url }))
                    "feed" -> return (encode (JSONDelFeed { feedurl = url }))
                    "user" -> return (encode (JSONDelUser { username = url }))
                    _      -> return ("" :: BL.ByteString)

       is <- S.fromLazyByteString jsBS
       sendRequest conn q (inputStreamBody is)

       receiveResponse conn (\p _ -> do
                               sc <- return $ getStatusCode p
                               case sc of
                                 200 -> do return (Just 200)
                                 _   -> do return Nothing)
