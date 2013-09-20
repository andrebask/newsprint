module Handler.Session where

import           Import hiding (filter)
import           Data.Aeson
import           Data.Aeson.Types
import           Data.Text                  (Text, pack, filter)
import           Data.ByteString            (ByteString)
import           Data.Time
import           Data.Text.ICU.Normalize
import           Database.Persist
import           Crypto.PasswordStore       (genSaltIO, exportSalt, verifyPassword)
import           Model
import           Network.HTTP.Types.Status
import           GHC.Generics

data JSONSession = JSONSession {
      expires :: UTCTime
    , token :: Text
    } deriving (Show, Generic)

data JSONAuth = JSONAuth {
      username :: Text
    , pwd :: ByteString
    } deriving (Show, Generic)

instance ToJSON JSONSession
instance FromJSON JSONAuth

-- Retreive the submitted data from the user
postSessionR :: Handler Value
postSessionR = do
  (result :: Result Value) <- parseJsonBody
  case result of
    Success v
        -> case v of
             Object o
                 -> do (auth :: Result JSONAuth) <- return (fromJSON v)
                       case auth of
                         Success (JSONAuth u p) ->
                             do user <- runDB $ selectFirst [UserUsername ==. u] []
                                case user of
                                  Nothing -> sendFail
                                  Just (Entity _ (User e u pDB))
                                      -> if (verifyPassword p pDB) then
                                             do (exp, tk) <- tryInsert u
                                                returnJson $ JSONSession exp tk
                                         else do
                                           sendFail
                         Error e -> sendFail
             otherwise -> sendFail
    Error e
        -> sendFail


tryInsert :: Text -> Handler (UTCTime, Text)
tryInsert user = do
  now <- lift getCurrentTime
  sess <- runDB $ selectFirst [SessionUser ==. user] []
  case sess of
    Nothing -> createSession
    Just (Entity _ (Session expires user token))
        -> case (expires < now) of
             True  -> createSession
             False -> return (expires, token)

 where createSession = do exp <- lift expiresTime
                          sIO <- lift genSaltIO
                          salt <- lift $ return $ exportSalt sIO
                          _ <- runDB $ insert (Session exp user $ clean salt)
                          return (exp, clean salt)
       createSession :: Handler (UTCTime, Text)

clean :: ByteString -> Text
clean salt = filter
             (\c -> case c of
                      '\\' -> False
                      '\"' -> False
                      '/' -> False
                      '=' -> False
                      '?' -> False
                      '|' -> False
                      '&' -> False
                      '+' -> False
                      _ -> True)
             (normalize NFKD $ pack $ show salt)

expiresTime :: IO UTCTime
expiresTime = do now <- getCurrentTime
                 return (addUTCTime 86400 now)

sendFail :: Handler Value
sendFail = sendResponseStatus status400 emptyObject