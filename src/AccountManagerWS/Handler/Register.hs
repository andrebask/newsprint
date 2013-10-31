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

module Handler.Register
    (postRegisterR)
where

import Data.ByteString hiding (isInfixOf)
import Data.Aeson.Types
import Import hiding (catch)
import Network.HTTP.Types.Status
import GHC.Generics
import Model (User)

data JSONUser = JSONUser {
       email :: Text
     , username :: Text
     , pwdHash :: ByteString
     } deriving (Show, Generic)

instance FromJSON JSONUser

-- Retreive the submitted data from the user
postRegisterR :: Handler ()
postRegisterR = do (result :: Result Value) <- parseJsonBody
                   case result of
                     Success v
                         -> case v of
                              Object o -> do (user :: Result JSONUser)
                                                 <- return (fromJSON v)
                                             case user of
                                               Success (JSONUser e u p) -> tryInsert e u p
                                               Error e -> sendResponseStatus status400 ()
                              otherwise -> sendResponseStatus status400 ()
                     Error e
                         -> sendResponseStatus status400 ()


tryInsert :: Text -> Text -> ByteString -> Handler ()
tryInsert email user pwd = do userId <- runDB $ insertUnique $ User email user pwd
                              case userId of
                                Nothing -> sendResponseStatus status400 ()
                                Just userId -> sendResponse ()
