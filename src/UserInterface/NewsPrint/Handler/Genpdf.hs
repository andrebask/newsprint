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

data Link = Link {
       link :: Text
     } deriving (Show, Generic)

data LinkArray = LinkArray {
       links :: [Link]
     } deriving (Show, Generic)

instance ToJSON Link
instance ToJSON LinkArray

postGenpdfR :: Handler ()
postGenpdfR = do itemType <- runInputPost $ ireq hiddenField "type"
                 items <- runInputPost $ ireq selectionField itemType
                 let path = case itemType of
                              "link" -> "/page"
                              "feed" -> "/rss"
                 filename <- lift $ withConnection (openConnection "127.0.0.1" 8080)
                                                   (submitItems items path)
                 case filename of
                   Just f -> do addHeader "Location" $ append "http://localhost:8080/pdf/" f
                                sendResponseStatus status303 ("" :: Text)
                   Nothing  -> redirect SessionR
                   _  -> redirect HomeR

submitItems :: [Text] -> B.ByteString -> Connection -> IO (Maybe Text)
submitItems items path conn =
    do laBS <- return (encode (LinkArray {links = [Link url | url <- items]}))
       is <- S.fromLazyByteString laBS
       len <- return $ BL.length laBS

       q <- buildRequest $ do
              http POST $ B.append path "/pdf"
              setContentType "application/json"
              -- setAccept "application/json"
              setContentLength len

       sendRequest conn q (inputStreamBody is)

       receiveResponse conn (\p i -> do
                               stream <- S.read i
                               case stream of
                                 Just bytes -> return $ Just $ decodeUtf8 bytes
                                 Nothing    -> return Nothing)

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

