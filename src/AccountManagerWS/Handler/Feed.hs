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