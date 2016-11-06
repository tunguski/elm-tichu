module Msg exposing (..)


import Window exposing (Size)
import Http


import Config
import Component exposing (Component)
import Task.Task as Task
import Member.Member as Member
import Report.Report as Report
import Dashboard
import TableView
import SessionModel exposing (Session)
import LoginScreen


type Msg
  = None
  | InitialWindowSize
  | ToggleHamburgerMenu 
  | PlayAsGuest
  | GetSession (Result Http.Error Session)

  | Resize Size 
  | ToggleSideMenu Bool 
  | ChangeView MenuEntry

  | Login LoginScreen.Msg
  | Dashboard Dashboard.Msg 
  | Task Task.Msg
  | Member Member.Msg
  | Report Report.Msg
  | Table TableView.Msg


type MenuEntry
  = ME_Dashboard 
  | ME_Table String
  | ME_Task Task.Pages
  | ME_Member Member.Pages
  | ME_Report Report.Pages


