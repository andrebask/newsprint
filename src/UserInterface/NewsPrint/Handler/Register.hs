{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE ScopedTypeVariables   #-}

module Handler.Register
    (postRegisterR)
where

import Data.Text (isInfixOf, splitOn)
import Data.ByteString hiding (isInfixOf)
import Data.Text.Encoding (encodeUtf8)
import Data.Aeson
import Crypto.PasswordStore
import Control.Exception hiding (Handler, catch)
import Import hiding (catch)
import Control.Exception.Lifted (catch)
import Control.Monad (void)
import qualified System.IO.Streams as S
import Network.Http.Client
import GHC.Generics

data JSONUser = JSONUser {
       email :: Text
     , username :: Text
     , pwdHash :: ByteString
     } deriving (Show, Generic)

instance ToJSON JSONUser

-- Retreive the submitted data from the user
postRegisterR :: Handler ()
postRegisterR = do email <- runInputPost $ ireq textField "email"
                   user  <- runInputPost $ ireq textField "user"
                   pwd   <- runInputPost $ ireq textField "pwd"
                   cpwd  <- runInputPost $ ireq textField "cpwd"
                   if pwd == cpwd && isValidEmail email
                      then do
                        pwdbs <- liftIO $ hashedPwd pwd
                        sc <- lift $ withConnection (openConnection "127.0.0.1" 3000)
                                                    (sendUserData email user pwdbs)
                        case sc of
                          Just 200 -> do setSession "user" user
                                         sendFile "text/html" "static/home_ok.html"
                          Nothing  -> redirect HomeR
                      else do
                        redirect HomeR

sendUserData :: Text -> Text -> ByteString -> Connection -> IO (Maybe StatusCode)
sendUserData e u p c =
    do q <- buildRequest $ do
              http POST "/register"
              setContentType "application/json"
              setAccept "application/json"

       juBS <- return (encode (JSONUser {email = e, username = u, pwdHash = p}))
       is <- S.fromLazyByteString juBS
       sendRequest c q (inputStreamBody is)

       receiveResponse c (\p i -> do
                            sc <- return $ getStatusCode p
                            case sc of
                              200 -> do return (Just 200)
                              _   -> do return Nothing)


isValidEmail :: Text -> Bool
isValidEmail s = case splitOn "@" s of
                   [name, domain] -> (isInfixOf "." domain) &&
                                     not (isInfixOf " " name) &&
                                     not (isInfixOf " " domain)
                   _ -> False

hashedPwd :: Text -> IO ByteString
hashedPwd pwd = do makePassword (encodeUtf8 pwd) 12
