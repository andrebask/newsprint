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

data JSONSubmit = JSONSubmit {
       title :: Text
     , url :: Text
     , content :: Text
     } deriving (Show, Generic)

instance ToJSON JSONSubmit

postSubmitR :: Handler ()
postSubmitR = do title <- runInputPost $ ireq textField "title"
                 url <- runInputPost $ ireq textField "url"
                 content <- runInputPost $ ireq textField "content"
                 u <- lookupSession "user"
                 case u of
                   Nothing -> do { setUltDestCurrent; redirect HomeR }
                   Just user
                       -> do token <- lookupSession "token"
                             let tk = case token of
                                        Nothing -> ("" :: Text)
                                        Just t -> t
                             sc <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                                         (submitItem title url content tk)
                             case sc of
                               Just 200 -> redirect SessionR
                               Nothing  -> redirect HomeR
                               _  -> redirect HomeR

submitItem :: Text -> Text -> Text -> Text -> Connection -> IO (Maybe StatusCode)
submitItem t u cont token conn =
    do q <- buildRequest $ do
              http POST $ B.append "/submit/" $ encodeUtf8 token
              setContentType "application/json"
              setAccept "application/json"

       let c = if (isInfixOf "html" cont) then "html" else (detContentType cont)
       jsBS <- return (encode (JSONSubmit {title = decodeUrl t, url = decodeUrl u, content = c}))
       is <- S.fromLazyByteString jsBS
       sendRequest conn q (inputStreamBody is)

       receiveResponse conn (\p _ -> do
                               sc <- return $ getStatusCode p
                               case sc of
                                 200 -> do return (Just 200)
                                 _   -> do return Nothing)

detContentType :: Text -> Text
detContentType _ = pack "rss"

decodeUrl :: Text -> Text
decodeUrl t = decodeUtf8 $ urlDecode True $ encodeUtf8 t