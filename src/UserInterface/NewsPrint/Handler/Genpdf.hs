module Handler.Genpdf where

import Import
import Data.Aeson
import qualified System.IO.Streams as S
import Network.Http.Client
import Network.HTTP.Types.URI     (urlDecode)
import Network.HTTP.Types.Status
import GHC.Generics
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Text.Encoding
import Data.Text
import Data.Time
import Handler.Genepub hiding (submitItems)
import Control.Exception (SomeException)
import Control.Exception.Lifted (catch)

postGenpdfR :: Handler ()
postGenpdfR = do itemType <- runInputPost $ ireq hiddenField "type"
                 items <- catch (do runInputPost $ ireq selectionField itemType)
                                (\(e :: SomeException) -> redirect SessionR)
                 dates <- case itemType of
                            "link" -> return []
                            "feed" -> runInputPost $ ireq selectionField "feed_date"
                 let path = case itemType of
                              "link" -> "/page"
                              "feed" -> "/rss"
                 filename <- lift $ withConnection (openConnection "127.0.0.1" 8080)
                                                   (submitItems items dates path)
                 case filename of
                   Just f -> do _ <- case itemType of
                                        "feed" -> updateFeedTime items
                                        _ -> return ()
                                addHeader "Location" $ append "http://localhost:8080/pdf/" f
                                sendResponseStatus status303 ("" :: Text)
                   Nothing  -> redirect SessionR
                   _  -> redirect HomeR

submitItems :: [Text] -> [Text] -> B.ByteString -> Connection -> IO (Maybe Text)
submitItems items dates path conn =
    do laBS <- case dates of
                 (x:xs) -> return (encode (LinkArray {links = [Link url lread | url <- items, lread <- dates]}))
                 [] -> return (encode (LinkArray {links = [Link url "" | url <- items]}))
       is <- S.fromLazyByteString laBS
       len <- return $ BL.length laBS

       q <- buildRequest $ do
              http POST $ B.append path "/pdf"
              setContentType "application/json"
              setContentLength len

       sendRequest conn q (inputStreamBody is)

       receiveResponse conn (\p i -> do
                               stream <- S.read i
                               case stream of
                                 Just bytes -> return $ Just $ decodeUtf8 bytes
                                 Nothing    -> return Nothing)

