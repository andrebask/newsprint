module Handler.Link where

import           Import
import           Data.Aeson.Types
import           GHC.Generics
import           Network.HTTP.Types.Status
import           Data.Time

data LinkArray = LinkArray
     { links :: [Link]
     } deriving (Show, Generic)

instance ToJSON Link
instance ToJSON LinkArray

getLinkR :: Text -> Handler Value
getLinkR stk = do
  session <- runDB $ selectFirst [SessionToken ==. stk] []
  case session of
    Nothing -> sendFail
    Just (Entity _ (Session exp user _))
        -> do now <- lift getNow
              if exp > now then
                 do elinks <- runDB $ selectList [LinkUser ==. user] []
                    returnJson $ LinkArray [x | (Entity _ x) <- elinks]
               else do
                 sendFail

sendFail :: Handler Value
sendFail = sendResponseStatus status400 emptyObject

getNow :: IO UTCTime
getNow = do now <- getCurrentTime
            return now