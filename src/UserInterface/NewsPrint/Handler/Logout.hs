module Handler.Logout where

import Import

getLogoutR :: Handler ()
getLogoutR = do clearSession
                redirect HomeR