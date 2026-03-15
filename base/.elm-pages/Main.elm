port module Main exposing ( main )

{-|
@docs main
-}


import Api
import ApiRoute
import BackendTask
import Browser.Navigation
import Bytes
import Bytes.Decode
import Bytes.Encode
import Dict
import Effect
import ErrorPage
import FatalError
import Form
import Head
import Html
import Http
import Json.Decode
import Json.Encode
import Lamdera.Wire3
import Pages.ConcurrentSubmission
import Pages.Fetcher
import Pages.Flags
import Pages.Internal.NotFoundReason
import Pages.Internal.Platform
import Pages.Internal.ResponseSketch
import Pages.Internal.RoutePattern
import Pages.Navigation
import Pages.PageUrl
import PagesMsg
import Route
import Route.About
import Route.Blog.Slug_
import Route.Contact
import Route.Index
import Route.Portfolio
import Route.Portfolio.ContractionTimer
import Server.Request
import Server.Response
import Shared
import SharedTemplate
import Site
import SiteConfig
import Url
import UrlPath
import View


type alias Model =
    { global : Shared.Model
    , page : PageModel
    , current :
        Maybe { path :
            { path : UrlPath.UrlPath
            , query : Maybe String
            , fragment : Maybe String
            }
        , metadata : Maybe Route.Route
        , pageUrl : Maybe Pages.PageUrl.PageUrl
        }
    }


type PageModel
    = ModelPortfolio__ContractionTimer Route.Portfolio.ContractionTimer.Model
    | ModelBlog__Slug_ Route.Blog.Slug_.Model
    | ModelAbout Route.About.Model
    | ModelContact Route.Contact.Model
    | ModelPortfolio Route.Portfolio.Model
    | ModelIndex Route.Index.Model
    | ModelErrorPage____ ErrorPage.Model
    | NotFound


type Msg
    = MsgPortfolio__ContractionTimer Route.Portfolio.ContractionTimer.Msg
    | MsgBlog__Slug_ Route.Blog.Slug_.Msg
    | MsgAbout Route.About.Msg
    | MsgContact Route.Contact.Msg
    | MsgPortfolio Route.Portfolio.Msg
    | MsgIndex Route.Index.Msg
    | MsgGlobal Shared.Msg
    | OnPageChange
        { protocol : Url.Protocol
        , host : String
        , port_ : Maybe Int
        , path : UrlPath.UrlPath
        , query : Maybe String
        , fragment : Maybe String
        , metadata : Maybe Route.Route
        }
    | MsgErrorPage____ ErrorPage.Msg


type PageData
    = DataPortfolio__ContractionTimer Route.Portfolio.ContractionTimer.Data
    | DataBlog__Slug_ Route.Blog.Slug_.Data
    | DataAbout Route.About.Data
    | DataContact Route.Contact.Data
    | DataPortfolio Route.Portfolio.Data
    | DataIndex Route.Index.Data
    | Data404NotFoundPage____
    | DataErrorPage____ ErrorPage.ErrorPage


type ActionData
    = ActionDataPortfolio__ContractionTimer
        Route.Portfolio.ContractionTimer.ActionData
    | ActionDataBlog__Slug_ Route.Blog.Slug_.ActionData
    | ActionDataAbout Route.About.ActionData
    | ActionDataContact Route.Contact.ActionData
    | ActionDataPortfolio Route.Portfolio.ActionData
    | ActionDataIndex Route.Index.ActionData


main :
    Platform.Program Pages.Internal.Platform.Flags (Pages.Internal.Platform.Model Model PageData ActionData Shared.Data) (Pages.Internal.Platform.Msg Msg PageData ActionData Shared.Data ErrorPage.ErrorPage)
main =
    Pages.Internal.Platform.application
        { init = init Nothing
        , update = update
        , subscriptions = subscriptions
        , sharedData = Shared.template.data
        , data = dataForRoute
        , action = action
        , onActionData = onActionData
        , view = view
        , handleRoute = handleRoute
        , getStaticRoutes = BackendTask.succeed []
        , urlToRoute = Route.urlToRoute
        , routeToPath =
            \route -> Maybe.withDefault [] (Maybe.map Route.routeToPath route)
        , site = Nothing
        , toJsPort = toJsPort
        , fromJsPort = fromJsPort Basics.identity
        , gotBatchSub = Sub.none
        , hotReloadData = hotReloadData Basics.identity
        , pageDataFromJs = pageDataFromJs Basics.identity
        , onPageChange = OnPageChange
        , apiRoutes = \htmlToString -> []
        , pathPatterns = routePatterns3
        , basePath = Route.baseUrlAsPath
        , sendPageData = sendPageData
        , byteEncodePageData = byteEncodePageData
        , byteDecodePageData = byteDecodePageData
        , encodeResponse = encodeResponse
        , encodeAction = encodeActionData
        , decodeResponse = decodeResponse
        , globalHeadTags = Nothing
        , cmdToEffect = Effect.fromCmd
        , perform = Effect.perform
        , errorStatusCode = ErrorPage.statusCode
        , notFoundPage = ErrorPage.notFound
        , internalError = ErrorPage.internalError
        , errorPageToData = DataErrorPage____
        , notFoundRoute = Nothing
        }


dataForRoute :
    Server.Request.Request
    -> Maybe Route.Route
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response PageData ErrorPage.ErrorPage)
dataForRoute requestPayload maybeRoute =
    case maybeRoute of
        Nothing ->
            BackendTask.succeed
                (Server.Response.mapError
                     Basics.never
                     (Server.Response.withStatusCode
                          404
                          (Server.Response.render Data404NotFoundPage____)
                     )
                )
    
        Just justRoute ->
            case justRoute of
                Route.Portfolio__ContractionTimer ->
                    BackendTask.map
                        (Server.Response.map DataPortfolio__ContractionTimer)
                        (Route.Portfolio.ContractionTimer.route.data
                             requestPayload
                             {}
                        )
            
                Route.Blog__Slug_ routeParams ->
                    BackendTask.map
                        (Server.Response.map DataBlog__Slug_)
                        (Route.Blog.Slug_.route.data requestPayload routeParams)
            
                Route.About ->
                    BackendTask.map
                        (Server.Response.map DataAbout)
                        (Route.About.route.data requestPayload {})
            
                Route.Contact ->
                    BackendTask.map
                        (Server.Response.map DataContact)
                        (Route.Contact.route.data requestPayload {})
            
                Route.Portfolio ->
                    BackendTask.map
                        (Server.Response.map DataPortfolio)
                        (Route.Portfolio.route.data requestPayload {})
            
                Route.Index ->
                    BackendTask.map
                        (Server.Response.map DataIndex)
                        (Route.Index.route.data requestPayload {})


toTriple : a -> b -> c -> ( a, b, c )
toTriple a b c =
    ( a, b, c )


action :
    Server.Request.Request
    -> Maybe Route.Route
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action requestPayload maybeRoute =
    case maybeRoute of
        Nothing ->
            BackendTask.succeed (Server.Response.plainText "TODO")
    
        Just justRoute ->
            case justRoute of
                Route.Portfolio__ContractionTimer ->
                    BackendTask.map
                        (Server.Response.map
                             ActionDataPortfolio__ContractionTimer
                        )
                        (Route.Portfolio.ContractionTimer.route.action
                             requestPayload
                             {}
                        )
            
                Route.Blog__Slug_ routeParams ->
                    BackendTask.map
                        (Server.Response.map ActionDataBlog__Slug_)
                        (Route.Blog.Slug_.route.action
                             requestPayload
                             routeParams
                        )
            
                Route.About ->
                    BackendTask.map
                        (Server.Response.map ActionDataAbout)
                        (Route.About.route.action requestPayload {})
            
                Route.Contact ->
                    BackendTask.map
                        (Server.Response.map ActionDataContact)
                        (Route.Contact.route.action requestPayload {})
            
                Route.Portfolio ->
                    BackendTask.map
                        (Server.Response.map ActionDataPortfolio)
                        (Route.Portfolio.route.action requestPayload {})
            
                Route.Index ->
                    BackendTask.map
                        (Server.Response.map ActionDataIndex)
                        (Route.Index.route.action requestPayload {})


fooFn :
    (a -> PageModel)
    -> (b -> Msg)
    -> Model
    -> ( a, Effect.Effect b, Maybe Shared.Msg )
    -> ( PageModel, Effect.Effect Msg, ( Shared.Model, Effect.Effect Shared.Msg ) )
fooFn wrapModel wrapMsg model triple =
    case triple of
        ( a, b, c ) ->
            ( wrapModel a
            , Effect.map wrapMsg b
            , case c of
                Nothing ->
                    ( model.global, Effect.none )
              
                Just sharedMsg ->
                    Shared.template.update sharedMsg model.global
            )


templateSubscriptions :
    Maybe Route.Route -> UrlPath.UrlPath -> Model -> Sub.Sub Msg
templateSubscriptions route path model =
    case route of
        Nothing ->
            Sub.none
    
        Just justRoute ->
            case justRoute of
                Route.Portfolio__ContractionTimer ->
                    case model.page of
                        ModelPortfolio__ContractionTimer templateModel ->
                            Sub.map
                                MsgPortfolio__ContractionTimer
                                (Route.Portfolio.ContractionTimer.route.subscriptions
                                     {}
                                     path
                                     templateModel
                                     model.global
                                )
                    
                        _ ->
                            Sub.none
            
                Route.Blog__Slug_ routeParams ->
                    case model.page of
                        ModelBlog__Slug_ templateModel ->
                            Sub.map
                                MsgBlog__Slug_
                                (Route.Blog.Slug_.route.subscriptions
                                     routeParams
                                     path
                                     templateModel
                                     model.global
                                )
                    
                        _ ->
                            Sub.none
            
                Route.About ->
                    case model.page of
                        ModelAbout templateModel ->
                            Sub.map
                                MsgAbout
                                (Route.About.route.subscriptions
                                     {}
                                     path
                                     templateModel
                                     model.global
                                )
                    
                        _ ->
                            Sub.none
            
                Route.Contact ->
                    case model.page of
                        ModelContact templateModel ->
                            Sub.map
                                MsgContact
                                (Route.Contact.route.subscriptions
                                     {}
                                     path
                                     templateModel
                                     model.global
                                )
                    
                        _ ->
                            Sub.none
            
                Route.Portfolio ->
                    case model.page of
                        ModelPortfolio templateModel ->
                            Sub.map
                                MsgPortfolio
                                (Route.Portfolio.route.subscriptions
                                     {}
                                     path
                                     templateModel
                                     model.global
                                )
                    
                        _ ->
                            Sub.none
            
                Route.Index ->
                    case model.page of
                        ModelIndex templateModel ->
                            Sub.map
                                MsgIndex
                                (Route.Index.route.subscriptions
                                     {}
                                     path
                                     templateModel
                                     model.global
                                )
                    
                        _ ->
                            Sub.none


onActionData : ActionData -> Maybe Msg
onActionData actionData =
    case actionData of
        ActionDataPortfolio__ContractionTimer thisActionData ->
            Maybe.map
                (\mapUnpack ->
                     MsgPortfolio__ContractionTimer (mapUnpack thisActionData)
                )
                Route.Portfolio.ContractionTimer.route.onAction
    
        ActionDataBlog__Slug_ thisActionData ->
            Maybe.map
                (\mapUnpack -> MsgBlog__Slug_ (mapUnpack thisActionData))
                Route.Blog.Slug_.route.onAction
    
        ActionDataAbout thisActionData ->
            Maybe.map
                (\mapUnpack -> MsgAbout (mapUnpack thisActionData))
                Route.About.route.onAction
    
        ActionDataContact thisActionData ->
            Maybe.map
                (\mapUnpack -> MsgContact (mapUnpack thisActionData))
                Route.Contact.route.onAction
    
        ActionDataPortfolio thisActionData ->
            Maybe.map
                (\mapUnpack -> MsgPortfolio (mapUnpack thisActionData))
                Route.Portfolio.route.onAction
    
        ActionDataIndex thisActionData ->
            Maybe.map
                (\mapUnpack -> MsgIndex (mapUnpack thisActionData))
                Route.Index.route.onAction


byteEncodePageData : PageData -> Bytes.Encode.Encoder
byteEncodePageData pageData =
    case pageData of
        DataErrorPage____ thisPageData ->
            ErrorPage.w3_encode_ErrorPage thisPageData
    
        Data404NotFoundPage____ ->
            Bytes.Encode.unsignedInt8 0
    
        DataPortfolio__ContractionTimer thisPageData ->
            Route.Portfolio.ContractionTimer.w3_encode_Data thisPageData
    
        DataBlog__Slug_ thisPageData ->
            Route.Blog.Slug_.w3_encode_Data thisPageData
    
        DataAbout thisPageData ->
            Route.About.w3_encode_Data thisPageData
    
        DataContact thisPageData ->
            Route.Contact.w3_encode_Data thisPageData
    
        DataPortfolio thisPageData ->
            Route.Portfolio.w3_encode_Data thisPageData
    
        DataIndex thisPageData ->
            Route.Index.w3_encode_Data thisPageData


byteDecodePageData : Maybe Route.Route -> Bytes.Decode.Decoder PageData
byteDecodePageData maybeRoute =
    case maybeRoute of
        Nothing ->
            Bytes.Decode.fail
    
        Just route ->
            case route of
                Route.Portfolio__ContractionTimer ->
                    Bytes.Decode.map
                        DataPortfolio__ContractionTimer
                        Route.Portfolio.ContractionTimer.w3_decode_Data
            
                Route.Blog__Slug_ _ ->
                    Bytes.Decode.map
                        DataBlog__Slug_
                        Route.Blog.Slug_.w3_decode_Data
            
                Route.About ->
                    Bytes.Decode.map DataAbout Route.About.w3_decode_Data
            
                Route.Contact ->
                    Bytes.Decode.map DataContact Route.Contact.w3_decode_Data
            
                Route.Portfolio ->
                    Bytes.Decode.map
                        DataPortfolio
                        Route.Portfolio.w3_decode_Data
            
                Route.Index ->
                    Bytes.Decode.map DataIndex Route.Index.w3_decode_Data


apiPatterns : ApiRoute.ApiRoute ApiRoute.Response
apiPatterns =
    ApiRoute.single
        (ApiRoute.literal
             "api-patterns.json"
             (ApiRoute.succeed
                  (BackendTask.succeed
                       (Json.Encode.encode
                            0
                            (Json.Encode.list
                                 Basics.identity
                                 (List.map
                                      ApiRoute.toJson
                                      (Api.routes
                                           getStaticRoutes
                                           (\routesUnpack -> \unpack -> "")
                                      )
                                 )
                            )
                       )
                  )
             )
        )


init :
    Maybe Shared.Model
    -> Pages.Flags.Flags
    -> Shared.Data
    -> PageData
    -> Maybe ActionData
    -> Maybe { path :
        { path : UrlPath.UrlPath
        , query : Maybe String
        , fragment : Maybe String
        }
    , metadata : Maybe Route.Route
    , pageUrl : Maybe Pages.PageUrl.PageUrl
    }
    -> ( Model, Effect.Effect Msg )
init currentGlobalModel userFlags sharedData pageData actionData maybePagePath =
    let
        ( sharedModel, globalCmd ) =
            Maybe.withDefault
                (Shared.template.init userFlags maybePagePath)
                (Maybe.map
                     (\mapUnpack -> ( mapUnpack, Effect.none ))
                     currentGlobalModel
                )
        
        ( templateModel, templateCmd ) =
            case
                Maybe.map2
                    Tuple.pair
                    (Maybe.andThen .metadata maybePagePath)
                    (Maybe.map .path maybePagePath)
            of
                Nothing ->
                    initErrorPage pageData
            
                Just justRouteAndPath ->
                    case ( Tuple.first justRouteAndPath, pageData ) of
                        ( Route.Portfolio__ContractionTimer, DataPortfolio__ContractionTimer thisPageData ) ->
                            Tuple.mapBoth
                                ModelPortfolio__ContractionTimer
                                (Effect.map MsgPortfolio__ContractionTimer)
                                (Route.Portfolio.ContractionTimer.route.init
                                     sharedModel
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action =
                                         Maybe.andThen
                                             (\andThenUnpack ->
                                                  case andThenUnpack of
                                                      ActionDataPortfolio__ContractionTimer thisActionData ->
                                                          Just thisActionData
                                                  
                                                      _ ->
                                                          Nothing
                                             )
                                             actionData
                                     , routeParams = {}
                                     , path =
                                         (Tuple.second justRouteAndPath).path
                                     , url =
                                         Maybe.andThen .pageUrl maybePagePath
                                     , submit =
                                         Pages.Fetcher.submit
                                             Route.Portfolio.ContractionTimer.w3_decode_ActionData
                                     , navigation = Nothing
                                     , concurrentSubmissions = Dict.empty
                                     , pageFormState = Dict.empty
                                     }
                                )
                    
                        ( Route.Blog__Slug_ routeParams, DataBlog__Slug_ thisPageData ) ->
                            Tuple.mapBoth
                                ModelBlog__Slug_
                                (Effect.map MsgBlog__Slug_)
                                (Route.Blog.Slug_.route.init
                                     sharedModel
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action =
                                         Maybe.andThen
                                             (\andThenUnpack ->
                                                  case andThenUnpack of
                                                      ActionDataBlog__Slug_ thisActionData ->
                                                          Just thisActionData
                                                  
                                                      _ ->
                                                          Nothing
                                             )
                                             actionData
                                     , routeParams = routeParams
                                     , path =
                                         (Tuple.second justRouteAndPath).path
                                     , url =
                                         Maybe.andThen .pageUrl maybePagePath
                                     , submit =
                                         Pages.Fetcher.submit
                                             Route.Blog.Slug_.w3_decode_ActionData
                                     , navigation = Nothing
                                     , concurrentSubmissions = Dict.empty
                                     , pageFormState = Dict.empty
                                     }
                                )
                    
                        ( Route.About, DataAbout thisPageData ) ->
                            Tuple.mapBoth
                                ModelAbout
                                (Effect.map MsgAbout)
                                (Route.About.route.init
                                     sharedModel
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action =
                                         Maybe.andThen
                                             (\andThenUnpack ->
                                                  case andThenUnpack of
                                                      ActionDataAbout thisActionData ->
                                                          Just thisActionData
                                                  
                                                      _ ->
                                                          Nothing
                                             )
                                             actionData
                                     , routeParams = {}
                                     , path =
                                         (Tuple.second justRouteAndPath).path
                                     , url =
                                         Maybe.andThen .pageUrl maybePagePath
                                     , submit =
                                         Pages.Fetcher.submit
                                             Route.About.w3_decode_ActionData
                                     , navigation = Nothing
                                     , concurrentSubmissions = Dict.empty
                                     , pageFormState = Dict.empty
                                     }
                                )
                    
                        ( Route.Contact, DataContact thisPageData ) ->
                            Tuple.mapBoth
                                ModelContact
                                (Effect.map MsgContact)
                                (Route.Contact.route.init
                                     sharedModel
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action =
                                         Maybe.andThen
                                             (\andThenUnpack ->
                                                  case andThenUnpack of
                                                      ActionDataContact thisActionData ->
                                                          Just thisActionData
                                                  
                                                      _ ->
                                                          Nothing
                                             )
                                             actionData
                                     , routeParams = {}
                                     , path =
                                         (Tuple.second justRouteAndPath).path
                                     , url =
                                         Maybe.andThen .pageUrl maybePagePath
                                     , submit =
                                         Pages.Fetcher.submit
                                             Route.Contact.w3_decode_ActionData
                                     , navigation = Nothing
                                     , concurrentSubmissions = Dict.empty
                                     , pageFormState = Dict.empty
                                     }
                                )
                    
                        ( Route.Portfolio, DataPortfolio thisPageData ) ->
                            Tuple.mapBoth
                                ModelPortfolio
                                (Effect.map MsgPortfolio)
                                (Route.Portfolio.route.init
                                     sharedModel
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action =
                                         Maybe.andThen
                                             (\andThenUnpack ->
                                                  case andThenUnpack of
                                                      ActionDataPortfolio thisActionData ->
                                                          Just thisActionData
                                                  
                                                      _ ->
                                                          Nothing
                                             )
                                             actionData
                                     , routeParams = {}
                                     , path =
                                         (Tuple.second justRouteAndPath).path
                                     , url =
                                         Maybe.andThen .pageUrl maybePagePath
                                     , submit =
                                         Pages.Fetcher.submit
                                             Route.Portfolio.w3_decode_ActionData
                                     , navigation = Nothing
                                     , concurrentSubmissions = Dict.empty
                                     , pageFormState = Dict.empty
                                     }
                                )
                    
                        ( Route.Index, DataIndex thisPageData ) ->
                            Tuple.mapBoth
                                ModelIndex
                                (Effect.map MsgIndex)
                                (Route.Index.route.init
                                     sharedModel
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action =
                                         Maybe.andThen
                                             (\andThenUnpack ->
                                                  case andThenUnpack of
                                                      ActionDataIndex thisActionData ->
                                                          Just thisActionData
                                                  
                                                      _ ->
                                                          Nothing
                                             )
                                             actionData
                                     , routeParams = {}
                                     , path =
                                         (Tuple.second justRouteAndPath).path
                                     , url =
                                         Maybe.andThen .pageUrl maybePagePath
                                     , submit =
                                         Pages.Fetcher.submit
                                             Route.Index.w3_decode_ActionData
                                     , navigation = Nothing
                                     , concurrentSubmissions = Dict.empty
                                     , pageFormState = Dict.empty
                                     }
                                )
                    
                        _ ->
                            initErrorPage pageData
    in
    ( { global = sharedModel, page = templateModel, current = maybePagePath }
    , Effect.batch [ templateCmd, Effect.map MsgGlobal globalCmd ]
    )


update :
    Form.Model
    -> Dict.Dict String (Pages.ConcurrentSubmission.ConcurrentSubmission ActionData)
    -> Maybe Pages.Navigation.Navigation
    -> Shared.Data
    -> PageData
    -> Maybe Browser.Navigation.Key
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update pageFormState concurrentSubmissions navigation sharedData pageData navigationKey msg model =
    case msg of
        MsgErrorPage____ msg_ ->
            let
                ( updatedPageModel, pageCmd ) =
                    case ( model.page, pageData ) of
                        ( ModelErrorPage____ pageModel, DataErrorPage____ thisPageData ) ->
                            Tuple.mapBoth
                                ModelErrorPage____
                                (Effect.map MsgErrorPage____)
                                (ErrorPage.update thisPageData msg_ pageModel)
                    
                        _ ->
                            ( model.page, Effect.none )
            in
            ( { model | page = updatedPageModel }, pageCmd )
    
        MsgGlobal msg_ ->
            let
                ( sharedModel, globalCmd ) =
                    Shared.template.update msg_ model.global
            in
            ( { model | global = sharedModel }, Effect.map MsgGlobal globalCmd )
    
        OnPageChange record ->
            let
                ( updatedModel, cmd ) =
                    init
                        (Just model.global)
                        Pages.Flags.PreRenderFlags
                        sharedData
                        pageData
                        Nothing
                        (Just
                             { path =
                                 { path = record.path
                                 , query = record.query
                                 , fragment = record.fragment
                                 }
                             , metadata = record.metadata
                             , pageUrl =
                                 Just
                                     { protocol = record.protocol
                                     , host = record.host
                                     , port_ = record.port_
                                     , path = record.path
                                     , query =
                                         Maybe.withDefault
                                             Dict.empty
                                             (Maybe.map
                                                  Pages.PageUrl.parseQueryParams
                                                  record.query
                                             )
                                     , fragment = record.fragment
                                     }
                             }
                        )
            in
            case Shared.template.onPageChange of
                Nothing ->
                    ( updatedModel, cmd )
            
                Just thingy ->
                    let
                        ( updatedGlobalModel, globalCmd ) =
                            Shared.template.update
                                (thingy
                                     { path = record.path
                                     , query = record.query
                                     , fragment = record.fragment
                                     }
                                )
                                model.global
                    in
                    ( { updatedModel | global = updatedGlobalModel }
                    , Effect.batch [ cmd, Effect.map MsgGlobal globalCmd ]
                    )
    
        MsgPortfolio__ContractionTimer msg_ ->
            case
                ( model.page
                , pageData
                , Maybe.map3
                    toTriple
                    (Maybe.andThen .metadata model.current)
                    (Maybe.andThen .pageUrl model.current)
                    (Maybe.map .path model.current)
                )
            of
                ( ModelPortfolio__ContractionTimer pageModel, DataPortfolio__ContractionTimer thisPageData, Just ( Route.Portfolio__ContractionTimer, pageUrl, justPage ) ) ->
                    let
                        ( updatedPageModel, pageCmd, globalModelAndCmd ) =
                            fooFn
                                ModelPortfolio__ContractionTimer
                                MsgPortfolio__ContractionTimer
                                model
                                (Route.Portfolio.ContractionTimer.route.update
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action = Nothing
                                     , routeParams = {}
                                     , path = justPage.path
                                     , url = Just pageUrl
                                     , submit =
                                         \options ->
                                             Pages.Fetcher.submit
                                                 Route.Portfolio.ContractionTimer.w3_decode_ActionData
                                                 options
                                     , navigation = navigation
                                     , concurrentSubmissions =
                                         Dict.map
                                             (\mapUnpack ->
                                                  Pages.ConcurrentSubmission.map
                                                      (\mapUnpack0 ->
                                                           case mapUnpack0 of
                                                               ActionDataPortfolio__ContractionTimer justActionData ->
                                                                   Just
                                                                       justActionData
                                                           
                                                               _ ->
                                                                   Nothing
                                                      )
                                             )
                                             concurrentSubmissions
                                     , pageFormState = pageFormState
                                     }
                                     msg_
                                     pageModel
                                     model.global
                                )
                        
                        ( newGlobalModel, newGlobalCmd ) =
                            globalModelAndCmd
                    in
                    ( { model
                        | page = updatedPageModel
                        , global = newGlobalModel
                      }
                    , Effect.batch
                        [ pageCmd, Effect.map MsgGlobal newGlobalCmd ]
                    )
            
                _ ->
                    ( model, Effect.none )
    
        MsgBlog__Slug_ msg_ ->
            case
                ( model.page
                , pageData
                , Maybe.map3
                    toTriple
                    (Maybe.andThen .metadata model.current)
                    (Maybe.andThen .pageUrl model.current)
                    (Maybe.map .path model.current)
                )
            of
                ( ModelBlog__Slug_ pageModel, DataBlog__Slug_ thisPageData, Just ( Route.Blog__Slug_ routeParams, pageUrl, justPage ) ) ->
                    let
                        ( updatedPageModel, pageCmd, globalModelAndCmd ) =
                            fooFn
                                ModelBlog__Slug_
                                MsgBlog__Slug_
                                model
                                (Route.Blog.Slug_.route.update
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action = Nothing
                                     , routeParams = routeParams
                                     , path = justPage.path
                                     , url = Just pageUrl
                                     , submit =
                                         \options ->
                                             Pages.Fetcher.submit
                                                 Route.Blog.Slug_.w3_decode_ActionData
                                                 options
                                     , navigation = navigation
                                     , concurrentSubmissions =
                                         Dict.map
                                             (\mapUnpack ->
                                                  Pages.ConcurrentSubmission.map
                                                      (\mapUnpack0 ->
                                                           case mapUnpack0 of
                                                               ActionDataBlog__Slug_ justActionData ->
                                                                   Just
                                                                       justActionData
                                                           
                                                               _ ->
                                                                   Nothing
                                                      )
                                             )
                                             concurrentSubmissions
                                     , pageFormState = pageFormState
                                     }
                                     msg_
                                     pageModel
                                     model.global
                                )
                        
                        ( newGlobalModel, newGlobalCmd ) =
                            globalModelAndCmd
                    in
                    ( { model
                        | page = updatedPageModel
                        , global = newGlobalModel
                      }
                    , Effect.batch
                        [ pageCmd, Effect.map MsgGlobal newGlobalCmd ]
                    )
            
                _ ->
                    ( model, Effect.none )
    
        MsgAbout msg_ ->
            case
                ( model.page
                , pageData
                , Maybe.map3
                    toTriple
                    (Maybe.andThen .metadata model.current)
                    (Maybe.andThen .pageUrl model.current)
                    (Maybe.map .path model.current)
                )
            of
                ( ModelAbout pageModel, DataAbout thisPageData, Just ( Route.About, pageUrl, justPage ) ) ->
                    let
                        ( updatedPageModel, pageCmd, globalModelAndCmd ) =
                            fooFn
                                ModelAbout
                                MsgAbout
                                model
                                (Route.About.route.update
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action = Nothing
                                     , routeParams = {}
                                     , path = justPage.path
                                     , url = Just pageUrl
                                     , submit =
                                         \options ->
                                             Pages.Fetcher.submit
                                                 Route.About.w3_decode_ActionData
                                                 options
                                     , navigation = navigation
                                     , concurrentSubmissions =
                                         Dict.map
                                             (\mapUnpack ->
                                                  Pages.ConcurrentSubmission.map
                                                      (\mapUnpack0 ->
                                                           case mapUnpack0 of
                                                               ActionDataAbout justActionData ->
                                                                   Just
                                                                       justActionData
                                                           
                                                               _ ->
                                                                   Nothing
                                                      )
                                             )
                                             concurrentSubmissions
                                     , pageFormState = pageFormState
                                     }
                                     msg_
                                     pageModel
                                     model.global
                                )
                        
                        ( newGlobalModel, newGlobalCmd ) =
                            globalModelAndCmd
                    in
                    ( { model
                        | page = updatedPageModel
                        , global = newGlobalModel
                      }
                    , Effect.batch
                        [ pageCmd, Effect.map MsgGlobal newGlobalCmd ]
                    )
            
                _ ->
                    ( model, Effect.none )
    
        MsgContact msg_ ->
            case
                ( model.page
                , pageData
                , Maybe.map3
                    toTriple
                    (Maybe.andThen .metadata model.current)
                    (Maybe.andThen .pageUrl model.current)
                    (Maybe.map .path model.current)
                )
            of
                ( ModelContact pageModel, DataContact thisPageData, Just ( Route.Contact, pageUrl, justPage ) ) ->
                    let
                        ( updatedPageModel, pageCmd, globalModelAndCmd ) =
                            fooFn
                                ModelContact
                                MsgContact
                                model
                                (Route.Contact.route.update
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action = Nothing
                                     , routeParams = {}
                                     , path = justPage.path
                                     , url = Just pageUrl
                                     , submit =
                                         \options ->
                                             Pages.Fetcher.submit
                                                 Route.Contact.w3_decode_ActionData
                                                 options
                                     , navigation = navigation
                                     , concurrentSubmissions =
                                         Dict.map
                                             (\mapUnpack ->
                                                  Pages.ConcurrentSubmission.map
                                                      (\mapUnpack0 ->
                                                           case mapUnpack0 of
                                                               ActionDataContact justActionData ->
                                                                   Just
                                                                       justActionData
                                                           
                                                               _ ->
                                                                   Nothing
                                                      )
                                             )
                                             concurrentSubmissions
                                     , pageFormState = pageFormState
                                     }
                                     msg_
                                     pageModel
                                     model.global
                                )
                        
                        ( newGlobalModel, newGlobalCmd ) =
                            globalModelAndCmd
                    in
                    ( { model
                        | page = updatedPageModel
                        , global = newGlobalModel
                      }
                    , Effect.batch
                        [ pageCmd, Effect.map MsgGlobal newGlobalCmd ]
                    )
            
                _ ->
                    ( model, Effect.none )
    
        MsgPortfolio msg_ ->
            case
                ( model.page
                , pageData
                , Maybe.map3
                    toTriple
                    (Maybe.andThen .metadata model.current)
                    (Maybe.andThen .pageUrl model.current)
                    (Maybe.map .path model.current)
                )
            of
                ( ModelPortfolio pageModel, DataPortfolio thisPageData, Just ( Route.Portfolio, pageUrl, justPage ) ) ->
                    let
                        ( updatedPageModel, pageCmd, globalModelAndCmd ) =
                            fooFn
                                ModelPortfolio
                                MsgPortfolio
                                model
                                (Route.Portfolio.route.update
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action = Nothing
                                     , routeParams = {}
                                     , path = justPage.path
                                     , url = Just pageUrl
                                     , submit =
                                         \options ->
                                             Pages.Fetcher.submit
                                                 Route.Portfolio.w3_decode_ActionData
                                                 options
                                     , navigation = navigation
                                     , concurrentSubmissions =
                                         Dict.map
                                             (\mapUnpack ->
                                                  Pages.ConcurrentSubmission.map
                                                      (\mapUnpack0 ->
                                                           case mapUnpack0 of
                                                               ActionDataPortfolio justActionData ->
                                                                   Just
                                                                       justActionData
                                                           
                                                               _ ->
                                                                   Nothing
                                                      )
                                             )
                                             concurrentSubmissions
                                     , pageFormState = pageFormState
                                     }
                                     msg_
                                     pageModel
                                     model.global
                                )
                        
                        ( newGlobalModel, newGlobalCmd ) =
                            globalModelAndCmd
                    in
                    ( { model
                        | page = updatedPageModel
                        , global = newGlobalModel
                      }
                    , Effect.batch
                        [ pageCmd, Effect.map MsgGlobal newGlobalCmd ]
                    )
            
                _ ->
                    ( model, Effect.none )
    
        MsgIndex msg_ ->
            case
                ( model.page
                , pageData
                , Maybe.map3
                    toTriple
                    (Maybe.andThen .metadata model.current)
                    (Maybe.andThen .pageUrl model.current)
                    (Maybe.map .path model.current)
                )
            of
                ( ModelIndex pageModel, DataIndex thisPageData, Just ( Route.Index, pageUrl, justPage ) ) ->
                    let
                        ( updatedPageModel, pageCmd, globalModelAndCmd ) =
                            fooFn
                                ModelIndex
                                MsgIndex
                                model
                                (Route.Index.route.update
                                     { data = thisPageData
                                     , sharedData = sharedData
                                     , action = Nothing
                                     , routeParams = {}
                                     , path = justPage.path
                                     , url = Just pageUrl
                                     , submit =
                                         \options ->
                                             Pages.Fetcher.submit
                                                 Route.Index.w3_decode_ActionData
                                                 options
                                     , navigation = navigation
                                     , concurrentSubmissions =
                                         Dict.map
                                             (\mapUnpack ->
                                                  Pages.ConcurrentSubmission.map
                                                      (\mapUnpack0 ->
                                                           case mapUnpack0 of
                                                               ActionDataIndex justActionData ->
                                                                   Just
                                                                       justActionData
                                                           
                                                               _ ->
                                                                   Nothing
                                                      )
                                             )
                                             concurrentSubmissions
                                     , pageFormState = pageFormState
                                     }
                                     msg_
                                     pageModel
                                     model.global
                                )
                        
                        ( newGlobalModel, newGlobalCmd ) =
                            globalModelAndCmd
                    in
                    ( { model
                        | page = updatedPageModel
                        , global = newGlobalModel
                      }
                    , Effect.batch
                        [ pageCmd, Effect.map MsgGlobal newGlobalCmd ]
                    )
            
                _ ->
                    ( model, Effect.none )


view :
    Form.Model
    -> Dict.Dict String (Pages.ConcurrentSubmission.ConcurrentSubmission ActionData)
    -> Maybe Pages.Navigation.Navigation
    -> { path : UrlPath.UrlPath, route : Maybe Route.Route }
    -> Maybe Pages.PageUrl.PageUrl
    -> Shared.Data
    -> PageData
    -> Maybe ActionData
    -> { view :
        Model
        -> { title : String, body : List (Html.Html (PagesMsg.PagesMsg Msg)) }
    , head : List Head.Tag
    }
view pageFormState concurrentSubmissions navigation page maybePageUrl globalData pageData actionData =
    case ( page.route, pageData ) of
        ( _, DataErrorPage____ data ) ->
            { view =
                \model ->
                    case model.page of
                        ModelErrorPage____ subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (\myMsg ->
                                          PagesMsg.fromMsg
                                              (MsgErrorPage____ myMsg)
                                     )
                                     (ErrorPage.view data subModel)
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        ( Just Route.Portfolio__ContractionTimer, DataPortfolio__ContractionTimer data ) ->
            let
                actionDataOrNothing thisActionData =
                    case thisActionData of
                        ActionDataPortfolio__ContractionTimer justActionData ->
                            Just justActionData
                    
                        _ ->
                            Nothing
            in
            { view =
                \model ->
                    case model.page of
                        ModelPortfolio__ContractionTimer subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (PagesMsg.map
                                          MsgPortfolio__ContractionTimer
                                     )
                                     (Route.Portfolio.ContractionTimer.route.view
                                          model.global
                                          subModel
                                          { data = data
                                          , sharedData = globalData
                                          , routeParams = {}
                                          , action =
                                              Maybe.andThen
                                                  actionDataOrNothing
                                                  actionData
                                          , path = page.path
                                          , url = maybePageUrl
                                          , submit =
                                              Pages.Fetcher.submit
                                                  Route.Portfolio.ContractionTimer.w3_decode_ActionData
                                          , navigation = navigation
                                          , concurrentSubmissions =
                                              Dict.map
                                                  (\mapUnpack ->
                                                       Pages.ConcurrentSubmission.map
                                                           actionDataOrNothing
                                                  )
                                                  concurrentSubmissions
                                          , pageFormState = pageFormState
                                          }
                                     )
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        ( Just (Route.Blog__Slug_ routeParams), DataBlog__Slug_ data ) ->
            let
                actionDataOrNothing thisActionData =
                    case thisActionData of
                        ActionDataBlog__Slug_ justActionData ->
                            Just justActionData
                    
                        _ ->
                            Nothing
            in
            { view =
                \model ->
                    case model.page of
                        ModelBlog__Slug_ subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (PagesMsg.map MsgBlog__Slug_)
                                     (Route.Blog.Slug_.route.view
                                          model.global
                                          subModel
                                          { data = data
                                          , sharedData = globalData
                                          , routeParams = routeParams
                                          , action =
                                              Maybe.andThen
                                                  actionDataOrNothing
                                                  actionData
                                          , path = page.path
                                          , url = maybePageUrl
                                          , submit =
                                              Pages.Fetcher.submit
                                                  Route.Blog.Slug_.w3_decode_ActionData
                                          , navigation = navigation
                                          , concurrentSubmissions =
                                              Dict.map
                                                  (\mapUnpack ->
                                                       Pages.ConcurrentSubmission.map
                                                           actionDataOrNothing
                                                  )
                                                  concurrentSubmissions
                                          , pageFormState = pageFormState
                                          }
                                     )
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        ( Just Route.About, DataAbout data ) ->
            let
                actionDataOrNothing thisActionData =
                    case thisActionData of
                        ActionDataAbout justActionData ->
                            Just justActionData
                    
                        _ ->
                            Nothing
            in
            { view =
                \model ->
                    case model.page of
                        ModelAbout subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (PagesMsg.map MsgAbout)
                                     (Route.About.route.view
                                          model.global
                                          subModel
                                          { data = data
                                          , sharedData = globalData
                                          , routeParams = {}
                                          , action =
                                              Maybe.andThen
                                                  actionDataOrNothing
                                                  actionData
                                          , path = page.path
                                          , url = maybePageUrl
                                          , submit =
                                              Pages.Fetcher.submit
                                                  Route.About.w3_decode_ActionData
                                          , navigation = navigation
                                          , concurrentSubmissions =
                                              Dict.map
                                                  (\mapUnpack ->
                                                       Pages.ConcurrentSubmission.map
                                                           actionDataOrNothing
                                                  )
                                                  concurrentSubmissions
                                          , pageFormState = pageFormState
                                          }
                                     )
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        ( Just Route.Contact, DataContact data ) ->
            let
                actionDataOrNothing thisActionData =
                    case thisActionData of
                        ActionDataContact justActionData ->
                            Just justActionData
                    
                        _ ->
                            Nothing
            in
            { view =
                \model ->
                    case model.page of
                        ModelContact subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (PagesMsg.map MsgContact)
                                     (Route.Contact.route.view
                                          model.global
                                          subModel
                                          { data = data
                                          , sharedData = globalData
                                          , routeParams = {}
                                          , action =
                                              Maybe.andThen
                                                  actionDataOrNothing
                                                  actionData
                                          , path = page.path
                                          , url = maybePageUrl
                                          , submit =
                                              Pages.Fetcher.submit
                                                  Route.Contact.w3_decode_ActionData
                                          , navigation = navigation
                                          , concurrentSubmissions =
                                              Dict.map
                                                  (\mapUnpack ->
                                                       Pages.ConcurrentSubmission.map
                                                           actionDataOrNothing
                                                  )
                                                  concurrentSubmissions
                                          , pageFormState = pageFormState
                                          }
                                     )
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        ( Just Route.Portfolio, DataPortfolio data ) ->
            let
                actionDataOrNothing thisActionData =
                    case thisActionData of
                        ActionDataPortfolio justActionData ->
                            Just justActionData
                    
                        _ ->
                            Nothing
            in
            { view =
                \model ->
                    case model.page of
                        ModelPortfolio subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (PagesMsg.map MsgPortfolio)
                                     (Route.Portfolio.route.view
                                          model.global
                                          subModel
                                          { data = data
                                          , sharedData = globalData
                                          , routeParams = {}
                                          , action =
                                              Maybe.andThen
                                                  actionDataOrNothing
                                                  actionData
                                          , path = page.path
                                          , url = maybePageUrl
                                          , submit =
                                              Pages.Fetcher.submit
                                                  Route.Portfolio.w3_decode_ActionData
                                          , navigation = navigation
                                          , concurrentSubmissions =
                                              Dict.map
                                                  (\mapUnpack ->
                                                       Pages.ConcurrentSubmission.map
                                                           actionDataOrNothing
                                                  )
                                                  concurrentSubmissions
                                          , pageFormState = pageFormState
                                          }
                                     )
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        ( Just Route.Index, DataIndex data ) ->
            let
                actionDataOrNothing thisActionData =
                    case thisActionData of
                        ActionDataIndex justActionData ->
                            Just justActionData
                    
                        _ ->
                            Nothing
            in
            { view =
                \model ->
                    case model.page of
                        ModelIndex subModel ->
                            Shared.template.view
                                globalData
                                page
                                model.global
                                (\myMsg -> PagesMsg.fromMsg (MsgGlobal myMsg))
                                (View.map
                                     (PagesMsg.map MsgIndex)
                                     (Route.Index.route.view
                                          model.global
                                          subModel
                                          { data = data
                                          , sharedData = globalData
                                          , routeParams = {}
                                          , action =
                                              Maybe.andThen
                                                  actionDataOrNothing
                                                  actionData
                                          , path = page.path
                                          , url = maybePageUrl
                                          , submit =
                                              Pages.Fetcher.submit
                                                  Route.Index.w3_decode_ActionData
                                          , navigation = navigation
                                          , concurrentSubmissions =
                                              Dict.map
                                                  (\mapUnpack ->
                                                       Pages.ConcurrentSubmission.map
                                                           actionDataOrNothing
                                                  )
                                                  concurrentSubmissions
                                          , pageFormState = pageFormState
                                          }
                                     )
                                )
                    
                        _ ->
                            modelMismatchView
            , head = []
            }
    
        _ ->
            { view =
                \_ ->
                    { title = "Page not found"
                    , body =
                        [ Html.div
                            []
                            [ Html.text "This page could not be found." ]
                        ]
                    }
            , head = []
            }


maybeToString : Maybe String -> String
maybeToString maybeString =
    case maybeString of
        Nothing ->
            "Nothing"
    
        Just string ->
            "Just " ++ stringToString string


stringToString : String -> String
stringToString string =
    "\"" ++ string ++ "\""


nonEmptyToString : ( String, List String ) -> String
nonEmptyToString nonEmpty =
    case nonEmpty of
        ( first, rest ) ->
            "( " ++ stringToString first ++ ", [ " ++ String.join
                                                                      ", "
                                                                      (List.map
                                                                                       stringToString
                                                                                       rest
                                                                      ) ++ " ] )"


listToString : List String -> String
listToString strings =
    "[ " ++ String.join ", " (List.map stringToString strings) ++ " ]"


initErrorPage : PageData -> ( PageModel, Effect.Effect Msg )
initErrorPage pageData =
    Tuple.mapBoth
        ModelErrorPage____
        (Effect.map MsgErrorPage____)
        (ErrorPage.init
             (case pageData of
                  DataErrorPage____ errorPage ->
                      errorPage
              
                  _ ->
                      ErrorPage.notFound
             )
        )


routePatterns : ApiRoute.ApiRoute ApiRoute.Response
routePatterns =
    ApiRoute.single
        (ApiRoute.literal
             "route-patterns.json"
             (ApiRoute.succeed
                  (BackendTask.succeed
                       (Json.Encode.encode
                            0
                            (Json.Encode.list
                                 (\listUnpack ->
                                      Json.Encode.object
                                          [ ( "kind"
                                            , Json.Encode.string listUnpack.kind
                                            )
                                          , ( "pathPattern"
                                            , Json.Encode.string
                                                  listUnpack.pathPattern
                                            )
                                          ]
                                 )
                                 [ { pathPattern =
                                       "/portfolio/contraction-timer"
                                   , kind =
                                       Route.Portfolio.ContractionTimer.route.kind
                                   }
                                 , { pathPattern = "/blog/:slug"
                                   , kind = Route.Blog.Slug_.route.kind
                                   }
                                 , { pathPattern = "/about"
                                   , kind = Route.About.route.kind
                                   }
                                 , { pathPattern = "/contact"
                                   , kind = Route.Contact.route.kind
                                   }
                                 , { pathPattern = "/portfolio"
                                   , kind = Route.Portfolio.route.kind
                                   }
                                 , { pathPattern = "/"
                                   , kind = Route.Index.route.kind
                                   }
                                 ]
                            )
                       )
                  )
             )
        )


pathsToGenerateHandler =
    ApiRoute.single
        (ApiRoute.literal
             "all-paths.json"
             (ApiRoute.succeed
                  (BackendTask.map2
                       (\map2Unpack ->
                            \unpack ->
                                Json.Encode.encode
                                    0
                                    (Json.Encode.list
                                         Json.Encode.string
                                         (map2Unpack ++ List.map
                                                                (\api ->
                                                                         "/" ++ api
                                                                )
                                                                unpack
                                         )
                                    )
                       )
                       (BackendTask.map
                            (List.map
                                 (\route ->
                                      UrlPath.toAbsolute (Route.toPath route)
                                 )
                            )
                            getStaticRoutes
                       )
                       (BackendTask.map
                            List.concat
                            (BackendTask.combine
                                 (List.map
                                      ApiRoute.getBuildTimeRoutes
                                      (routePatterns :: apiPatterns :: Api.routes
                                                                                   getStaticRoutes
                                                                                   (\routesUnpack ->
                                                                                                \unpack ->
                                                                                                    ""
                                                                                   )
                                      )
                                 )
                            )
                       )
                  )
             )
        )


getStaticRoutes :
    BackendTask.BackendTask FatalError.FatalError (List Route.Route)
getStaticRoutes =
    BackendTask.map
        List.concat
        (BackendTask.combine
             [ BackendTask.map
                 (List.map (\_ -> Route.Portfolio__ContractionTimer))
                 Route.Portfolio.ContractionTimer.route.staticRoutes
             , BackendTask.map
                 (List.map Route.Blog__Slug_)
                 Route.Blog.Slug_.route.staticRoutes
             , BackendTask.map
                 (List.map (\_ -> Route.About))
                 Route.About.route.staticRoutes
             , BackendTask.map
                 (List.map (\_ -> Route.Contact))
                 Route.Contact.route.staticRoutes
             , BackendTask.map
                 (List.map (\_ -> Route.Portfolio))
                 Route.Portfolio.route.staticRoutes
             , BackendTask.map
                 (List.map (\_ -> Route.Index))
                 Route.Index.route.staticRoutes
             ]
        )


handleRoute :
    Maybe Route.Route
    -> BackendTask.BackendTask FatalError.FatalError (Maybe Pages.Internal.NotFoundReason.NotFoundReason)
handleRoute maybeRoute =
    case maybeRoute of
        Nothing ->
            BackendTask.succeed Nothing
    
        Just route ->
            case route of
                Route.Portfolio__ContractionTimer ->
                    Route.Portfolio.ContractionTimer.route.handleRoute
                        { moduleName = [ "Portfolio", "ContractionTimer" ]
                        , routePattern =
                            { segments =
                                [ Pages.Internal.RoutePattern.StaticSegment
                                    "portfolio"
                                , Pages.Internal.RoutePattern.StaticSegment
                                    "contraction-timer"
                                ]
                            , ending = Nothing
                            }
                        }
                        (\param -> [])
                        {}
            
                Route.Blog__Slug_ routeParams ->
                    Route.Blog.Slug_.route.handleRoute
                        { moduleName = [ "Blog", "Slug_" ]
                        , routePattern =
                            { segments =
                                [ Pages.Internal.RoutePattern.StaticSegment
                                    "blog"
                                , Pages.Internal.RoutePattern.DynamicSegment
                                    "slug"
                                ]
                            , ending = Nothing
                            }
                        }
                        (\param -> [ ( "slug", stringToString param.slug ) ])
                        routeParams
            
                Route.About ->
                    Route.About.route.handleRoute
                        { moduleName = [ "About" ]
                        , routePattern =
                            { segments =
                                [ Pages.Internal.RoutePattern.StaticSegment
                                    "about"
                                ]
                            , ending = Nothing
                            }
                        }
                        (\param -> [])
                        {}
            
                Route.Contact ->
                    Route.Contact.route.handleRoute
                        { moduleName = [ "Contact" ]
                        , routePattern =
                            { segments =
                                [ Pages.Internal.RoutePattern.StaticSegment
                                    "contact"
                                ]
                            , ending = Nothing
                            }
                        }
                        (\param -> [])
                        {}
            
                Route.Portfolio ->
                    Route.Portfolio.route.handleRoute
                        { moduleName = [ "Portfolio" ]
                        , routePattern =
                            { segments =
                                [ Pages.Internal.RoutePattern.StaticSegment
                                    "portfolio"
                                ]
                            , ending = Nothing
                            }
                        }
                        (\param -> [])
                        {}
            
                Route.Index ->
                    Route.Index.route.handleRoute
                        { moduleName = [ "Index" ]
                        , routePattern =
                            { segments =
                                [ Pages.Internal.RoutePattern.StaticSegment
                                    "index"
                                ]
                            , ending = Nothing
                            }
                        }
                        (\param -> [])
                        {}


encodeActionData : ActionData -> Bytes.Encode.Encoder
encodeActionData actionData =
    case actionData of
        ActionDataPortfolio__ContractionTimer thisActionData ->
            Route.Portfolio.ContractionTimer.w3_encode_ActionData thisActionData
    
        ActionDataBlog__Slug_ thisActionData ->
            Route.Blog.Slug_.w3_encode_ActionData thisActionData
    
        ActionDataAbout thisActionData ->
            Route.About.w3_encode_ActionData thisActionData
    
        ActionDataContact thisActionData ->
            Route.Contact.w3_encode_ActionData thisActionData
    
        ActionDataPortfolio thisActionData ->
            Route.Portfolio.w3_encode_ActionData thisActionData
    
        ActionDataIndex thisActionData ->
            Route.Index.w3_encode_ActionData thisActionData


subscriptions : Maybe Route.Route -> UrlPath.UrlPath -> Model -> Sub.Sub Msg
subscriptions route path model =
    Sub.batch
        [ Sub.map MsgGlobal (Shared.template.subscriptions path model.global)
        , templateSubscriptions route path model
        ]


modelMismatchView : { title : String, body : List (Html.Html msg) }
modelMismatchView =
    { title = "Model mismatch", body = [ Html.text "Model mismatch" ] }


port sendPageData :
    { oldThing : Json.Encode.Value, binaryPageData : Bytes.Bytes } -> Cmd msg


globalHeadTags :
    (Maybe { indent : Int, newLines : Bool } -> Html.Html Never -> String)
    -> BackendTask.BackendTask FatalError.FatalError (List Head.Tag)
globalHeadTags htmlToString =
    BackendTask.map
        List.concat
        (BackendTask.combine
             (Site.config.head :: List.filterMap
                                          ApiRoute.getGlobalHeadTagsBackendTask
                                          (Api.routes
                                                   getStaticRoutes
                                                   htmlToString
                                          )
             )
        )


encodePageDataForClient : PageData -> Bytes.Encode.Encoder
encodePageDataForClient pageData =
    case pageData of
        DataPortfolio__ContractionTimer thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 7
                , Route.Portfolio.ContractionTimer.w3_encode_Data thisPageData
                ]
    
        DataBlog__Slug_ thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 2
                , Route.Blog.Slug_.w3_encode_Data thisPageData
                ]
    
        DataAbout thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 1
                , Route.About.w3_encode_Data thisPageData
                ]
    
        DataContact thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 3
                , Route.Contact.w3_encode_Data thisPageData
                ]
    
        DataPortfolio thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 6
                , Route.Portfolio.w3_encode_Data thisPageData
                ]
    
        DataIndex thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 5
                , Route.Index.w3_encode_Data thisPageData
                ]
    
        Data404NotFoundPage____ ->
            Bytes.Encode.unsignedInt8 0
    
        DataErrorPage____ thisPageData ->
            Lamdera.Wire3.encodeSequenceWithoutLength
                [ Bytes.Encode.unsignedInt8 4
                , ErrorPage.w3_encode_ErrorPage thisPageData
                ]


encodeResponse :
    Pages.Internal.ResponseSketch.ResponseSketch PageData ActionData Shared.Data
    -> Bytes.Encode.Encoder
encodeResponse =
    Pages.Internal.ResponseSketch.w3_encode_ResponseSketch
        w3_encode_PageData
        w3_encode_ActionData
        Shared.w3_encode_Data


routePatterns3 : List Pages.Internal.RoutePattern.RoutePattern
routePatterns3 =
    [ { segments =
          [ Pages.Internal.RoutePattern.StaticSegment "portfolio"
          , Pages.Internal.RoutePattern.StaticSegment "contraction-timer"
          ]
      , ending = Nothing
      }
    , { segments =
          [ Pages.Internal.RoutePattern.StaticSegment "blog"
          , Pages.Internal.RoutePattern.DynamicSegment "slug"
          ]
      , ending = Nothing
      }
    , { segments = [ Pages.Internal.RoutePattern.StaticSegment "about" ]
      , ending = Nothing
      }
    , { segments = [ Pages.Internal.RoutePattern.StaticSegment "contact" ]
      , ending = Nothing
      }
    , { segments = [ Pages.Internal.RoutePattern.StaticSegment "portfolio" ]
      , ending = Nothing
      }
    , { segments = [ Pages.Internal.RoutePattern.StaticSegment "index" ]
      , ending = Nothing
      }
    ]


skipFrozenViewsPrefix : Bytes.Decode.Decoder a -> Bytes.Decode.Decoder a
skipFrozenViewsPrefix innerDecoder =
    Bytes.Decode.andThen
        (\andThenUnpack ->
             Bytes.Decode.andThen
                 (\andThenUnpack0 -> innerDecoder)
                 (Bytes.Decode.bytes andThenUnpack)
        )
        (Bytes.Decode.unsignedInt32 Bytes.BE)


decodeResponse :
    Bytes.Decode.Decoder (Pages.Internal.ResponseSketch.ResponseSketch PageData ActionData Shared.Data)
decodeResponse =
    skipFrozenViewsPrefix
        (Pages.Internal.ResponseSketch.w3_decode_ResponseSketch
             w3_decode_PageData
             w3_decode_ActionData
             Shared.w3_decode_Data
        )


port hotReloadData : (Bytes.Bytes -> msg) -> Sub msg


port pageDataFromJs : (Bytes.Bytes -> msg) -> Sub msg


port toJsPort :
    { json : Json.Encode.Value
    , bytes : List { key : String, data : Bytes.Bytes }
    }
    -> Cmd msg


port fromJsPort : (Json.Decode.Value -> msg) -> Sub msg


port gotBatchSub :
    (List { key : String, json : Json.Decode.Value, bytes : Maybe Bytes.Bytes }
    -> msg)
    -> Sub msg