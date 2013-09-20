module Handler.Genepub where

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

data Link = Link {
        link :: Text
       ,date :: Text
     } deriving (Show, Generic)

data LinkArray = LinkArray {
       links :: [Link]
     } deriving (Show, Generic)

data JSONUpdate = JSONUpdate {
         url :: Text
       , time :: UTCTime
     } deriving (Show, Generic)

data UpdateArray = UpdateArray {
         feeds :: [JSONUpdate]
     } deriving (Show, Generic)

instance ToJSON Link
instance ToJSON LinkArray
instance ToJSON JSONUpdate
instance ToJSON UpdateArray

postGenepubR :: Handler Html
postGenepubR = do itemType <- runInputPost $ ireq hiddenField "type"
                  items <- runInputPost $ ireq selectionField itemType
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
                                 addHeader "Location" $ append "http://localhost:8080/webreader/" f
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
              http POST $ B.append path "/epub"
              setContentType "application/json"
              setContentLength len

       sendRequest conn q (inputStreamBody is)

       receiveResponse conn (\p i -> do
                               stream <- S.read i
                               case stream of
                                 Just bytes -> return $ Just $ decodeUtf8 bytes
                                 Nothing    -> return Nothing)

updateFeedTime :: [Text] -> Handler ()
updateFeedTime items =
  do u <- lookupSession "user"
     case u of
       Nothing -> do return ()
       Just user
         -> do token <- lookupSession "token"
               let tk = case token of
                          Nothing -> ("" :: Text)
                          Just t -> t
               sc <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                           (submitUpdate items tk)
               return ()

submitUpdate :: [Text] -> Text -> Connection -> IO ()
submitUpdate items token conn =
    do now <- getNow
       uaBS <- return (encode (UpdateArray {feeds = [JSONUpdate url now | url <- items]}))
       is <- S.fromLazyByteString uaBS

       q <- buildRequest $ do
              http POST $ B.append "/update/" $ encodeUtf8 token
              setContentType "application/json"

       sendRequest conn q (inputStreamBody is)

       receiveResponse conn (\p i -> do return ())

selectionField :: Field Handler [Text]
selectionField = Field
    { fieldParse = \rawVals _fileVals ->
        case rawVals of
          [] -> return $ Right Nothing
          (x:xs) -> return $ Right $ Just rawVals
          _ -> return $ Left "Error"
    , fieldView = \idAttr nameAttr otherAttrs eResult isReq ->
        [whamlet||]
    , fieldEnctype = UrlEncoded
    }

getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now