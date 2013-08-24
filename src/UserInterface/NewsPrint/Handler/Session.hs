module Handler.Session where

import Import
import Data.Aeson
import qualified System.IO.Streams as S
import Network.Http.Client
import GHC.Generics
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Text.Encoding
import Data.Text (pack, unpack)
import Data.Time

data JSONSession = JSONSession {
      expires :: UTCTime
    , token :: Text
    } deriving (Show, Generic)

data JSONAuth = JSONAuth {
      username :: Text
    , pwd :: B.ByteString
    } deriving (Show, Generic)

data Link = Link
     { linkTitle :: Text
     , linkUrl :: Text
     , linkSite :: Text
     , linkUser :: Text
     , linkSaved :: UTCTime
     } deriving (Show, Generic)

data LinkArray = LinkArray
     { links :: [Link]
     } deriving (Show, Generic)

data Feed = Feed
     { feedTitle :: Text
     , feedUrl :: Text
     , feedSite :: Text
     , feedRead :: UTCTime
     , feedUser :: Text
     } deriving (Show, Generic)

data FeedArray = FeedArray
     { feeds :: [Feed]
     } deriving (Show, Generic)

instance FromJSON Link
instance FromJSON LinkArray
instance FromJSON Feed
instance FromJSON FeedArray

instance FromJSON JSONSession
instance ToJSON JSONAuth


getSessionR :: Handler Html
getSessionR = do user <- lookupSession "user"
                 token <- lookupSession "token"
                 e <- lookupSession "expires"
                 now <- lift getNow
                 case e of
                   Nothing -> do { clearSession; redirect HomeR }
                   Just exp
                        | (textToTime exp) < now -> do { clearSession; redirect HomeR }
                        | otherwise -> do
                              let tk = case token of
                                         Nothing -> ("" :: Text)
                                         Just t -> t
                              case user of
                                Nothing -> do { clearSession; redirect HomeR }
                                Just user -> do links <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                                                               (getLinkArray tk)
                                                feeds <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                                                               (getFeedArray tk)
                                                showPage links feeds

getLinkArray :: Text -> Connection -> IO [Link]
getLinkArray token c =
    do q <- buildRequest $ do
              http GET $ B.append "/links/" $ encodeUtf8 token
              setContentType "application/json"
              setAccept "application/json"

       sendRequest c q emptyBody

       receiveResponse c (\p i -> do
                            stream <- S.read i
                            case stream of
                              Just bytes -> do dby <- return $ decode $ fromStrict bytes
                                               case dby of
                                                 Nothing -> return []
                                                 Just (LinkArray links) -> return links
                              Nothing    -> return [])

getFeedArray :: Text -> Connection -> IO [Feed]
getFeedArray token c =
    do q <- buildRequest $ do
              http GET $ B.append "/feeds/" $ encodeUtf8 token
              setContentType "application/json"
              setAccept "application/json"

       sendRequest c q emptyBody

       receiveResponse c (\p i -> do
                            stream <- S.read i
                            case stream of
                              Just bytes -> do dby <- return $ decode $ fromStrict bytes
                                               case dby of
                                                 Nothing -> return []
                                                 Just (FeedArray feeds) -> return feeds
                              Nothing    -> return [])

showPage :: [Link] -> [Feed] -> Handler Html
showPage links feeds = defaultLayout $(widgetFile "UI")

postSessionR :: Handler ()
postSessionR = do user <- runInputPost $ ireq textField "user"
                  pwd <- runInputPost $ ireq textField "pwd"
                  mtk <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                               (getSessionToken user pwd)
                  case mtk of
                    Just (tk, exp) -> do setSession "token" tk
                                         setSession "expires" (timeToText exp)
                                         setSession "user" user
                                         redirectUltDest SessionR
                    Nothing -> redirect HomeR

getSessionToken :: Text -> Text -> Connection -> IO (Maybe (Text, UTCTime))
getSessionToken u p c =
    do q <- buildRequest $ do
              http POST "/session"
              setContentType "application/json"
              setAccept "application/json"

       jaBS <- return (encode (JSONAuth {username = u, pwd = (encodeUtf8 p)}))
       is <- S.fromLazyByteString jaBS
       sendRequest c q (inputStreamBody is)

       receiveResponse c (\p i -> do
                            stream <- S.read i
                            case stream of
                              Just bytes -> do dby <- return $ decode $ fromStrict bytes
                                               case dby of
                                                 Nothing -> do return Nothing
                                                 Just (JSONSession exp tk) -> do return $ Just (tk, exp)
                              Nothing    -> do return Nothing)

fromStrict :: B.ByteString -> BL.ByteString
fromStrict strict = BL.fromChunks [strict]

getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now

textToTime :: Text -> UTCTime
textToTime txt = (read (unpack txt) :: UTCTime)

timeToText :: UTCTime -> Text
timeToText t = pack $ show t