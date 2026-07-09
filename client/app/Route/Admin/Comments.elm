module Route.Admin.Comments exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Css exposing (auto, block, display, displayFlex, fitContent, important, justifyContent, left, margin, maxWidth, none, pct, spaceAround, spaceBetween, textAlign, underline, width)
import Effect exposing (Effect(..))
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html.Styled exposing (Html, br, div, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Http
import Json.Decode as D exposing (Decoder, andThen, succeed)
import Json.Encode as E
import OWBTheme exposing (faButton, theme)
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route.Portfolio.ContractionTimer exposing (Msg(..))
import RouteBuilder exposing (App)
import Server.Request exposing (Request)
import Server.Response as Response exposing (Response)
import Settings
import Shared
import Task
import Time
import TimeUtils
import Url exposing (Protocol(..))
import UrlPath
import View exposing (View)


type alias Model =
    { zone : Time.Zone
    , mode : Mode
    , viewMode : ViewMode
    , comments : List AdminComment
    }


type Mode
    = DeleteConfirm Int
    | DeleteAllConfirm String
    | View


type ViewMode
    = ViewAll
    | ViewRejected
    | ViewApproved
    | ViewPending


type Msg
    = AdjustTimeZone Time.Zone
    | ConfirmDeleteAll String
    | DeleteAll String
    | ConfirmDelete Int
    | Delete Int
    | CancelDelete
    | DisapproveComment AdminComment
    | ApproveComment AdminComment
    | CommentSaved (Result Http.Error (List AdminComment))
    | GetComments (Result Http.Error (List AdminComment))
    | ShowApproved
    | ShowRejected
    | ShowAll
    | ShowPending


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


type alias AdminComment =
    { id : Int
    , member_id : Int
    , post_id : Int
    , remote_addr : String
    , commented_at : Time.Posix
    , commented_by : String
    , content : String
    , approved : Int
    }


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init _ _ =
    ( Model Time.utc View ViewPending []
    , Effect.batch
        [ Effect.fromCmd (Task.perform AdjustTimeZone Time.here)
        , Effect.fromCmd
            (Http.get
                { url = Settings.apiUrl ++ "/admin/comments/"
                , expect = Http.expectJson GetComments adminCommentDecoder
                }
            )
        ]
    )


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.serverRender
        { head = head
        , data = data
        , action = \_ _ -> BackendTask.succeed (Response.render {})
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , subscriptions = \_ _ _ _ -> Sub.none
            , update = update
            , init = init
            }


data : RouteParams -> Request -> BackendTask FatalError (Response Data ErrorPage)
data _ _ =
    BackendTask.succeed
        (Response.render {})


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update _ _ msg model =
    case msg of
        AdjustTimeZone zone ->
            ( { model | zone = zone }, Effect.none )

        ConfirmDeleteAll ip ->
            ( { model | mode = DeleteAllConfirm ip }, Effect.none )

        DeleteAll remote_addr ->
            ( { model | mode = View }
            , Effect.fromCmd
                (Http.request
                    { method = "DELETE"
                    , headers = []
                    , url = Settings.apiUrl ++ "/admin/comments/" ++ remote_addr
                    , body = Http.emptyBody
                    , expect = Http.expectJson CommentSaved adminCommentDecoder
                    , timeout = Nothing
                    , tracker = Nothing
                    }
                )
            )

        ConfirmDelete id ->
            ( { model | mode = DeleteConfirm id }, Effect.none )

        Delete comment_id ->
            ( { model | mode = View }
            , Effect.fromCmd
                (Http.request
                    { method = "DELETE"
                    , headers = []
                    , url = Settings.apiUrl ++ "/admin/comment/" ++ String.fromInt comment_id
                    , body = Http.emptyBody
                    , expect = Http.expectJson CommentSaved adminCommentDecoder
                    , timeout = Nothing
                    , tracker = Nothing
                    }
                )
            )

        CancelDelete ->
            ( { model | mode = View }, Effect.none )

        DisapproveComment comment ->
            let
                rejectComment =
                    { comment | approved = 2 }

                saveCmd =
                    Http.request
                        { method = "PUT"
                        , headers = []
                        , url = Settings.apiUrl ++ "/admin/comment/" ++ String.fromInt comment.id
                        , body = Http.jsonBody (commentEncoder rejectComment)
                        , expect = Http.expectJson CommentSaved adminCommentDecoder
                        , timeout = Nothing
                        , tracker = Nothing
                        }
            in
            ( { model | mode = View }
            , Effect.fromCmd
                saveCmd
            )

        ApproveComment comment ->
            let
                approveComment =
                    { comment | approved = 1 }

                saveCmd =
                    Http.request
                        { method = "PUT"
                        , headers = []
                        , url = Settings.apiUrl ++ "/admin/comment/" ++ String.fromInt comment.id
                        , body = Http.jsonBody (commentEncoder approveComment)
                        , expect = Http.expectJson CommentSaved adminCommentDecoder
                        , timeout = Nothing
                        , tracker = Nothing
                        }
            in
            ( { model | mode = View }
            , Effect.fromCmd
                saveCmd
            )

        CommentSaved response ->
            case response of
                Ok comments ->
                    ( { model | comments = comments }, Effect.none )

                Err _ ->
                    ( model, Effect.none )

        GetComments response ->
            case response of
                Ok comments ->
                    ( { model | comments = comments }, Effect.none )

                Err _ ->
                    ( model, Effect.none )

        ShowAll ->
            ( { model | viewMode = ViewAll }, Effect.none )

        ShowApproved ->
            ( { model | viewMode = ViewApproved }, Effect.none )

        ShowRejected ->
            ( { model | viewMode = ViewRejected }, Effect.none )

        ShowPending ->
            ( { model | viewMode = ViewPending }, Effect.none )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "oldworldboa"
        , image =
            { url = [ "images", "icon-png.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Welcome to The Byte Station!"
        , locale = Nothing
        , title = "Blog - Welcome to the Byte Station!"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view _ _ model =
    { title = "Comment Admin"
    , body =
        [ Html.Styled.toUnstyled
            (div []
                (List.append
                    [ div [ css [ displayFlex, justifyContent Css.center, width (pct 100) ] ]
                        [ OWBTheme.tabBtn
                            (case model.viewMode of
                                ViewAll ->
                                    [ css [ important (Css.textDecoration underline) ]
                                    , onClick (PagesMsg.fromMsg ShowAll)
                                    ]

                                _ ->
                                    [ css []
                                    , onClick (PagesMsg.fromMsg ShowAll)
                                    ]
                            )
                            [ text "All" ]
                        , OWBTheme.tabBtn
                            (case model.viewMode of
                                ViewPending ->
                                    [ css [ important (Css.textDecoration underline) ]
                                    , onClick (PagesMsg.fromMsg ShowPending)
                                    ]

                                _ ->
                                    [ css []
                                    , onClick (PagesMsg.fromMsg ShowPending)
                                    ]
                            )
                            [ text "Pending" ]
                        , OWBTheme.tabBtn
                            (case model.viewMode of
                                ViewApproved ->
                                    [ css [ important (Css.textDecoration underline) ]
                                    , onClick (PagesMsg.fromMsg ShowApproved)
                                    ]

                                _ ->
                                    [ css []
                                    , onClick (PagesMsg.fromMsg ShowApproved)
                                    ]
                            )
                            [ text "Approved" ]
                        , OWBTheme.tabBtn
                            (case model.viewMode of
                                ViewRejected ->
                                    [ css [ important (Css.textDecoration underline) ]
                                    , onClick (PagesMsg.fromMsg ShowRejected)
                                    ]

                                _ ->
                                    [ css []
                                    , onClick (PagesMsg.fromMsg ShowRejected)
                                    ]
                            )
                            [ text "Rejected" ]
                        ]
                    , br [] []
                    , deleteConfirm model
                    ]
                    (getPostsHtml model)
                )
            )
        ]
    }


getPostsHtml : Model -> List (Html.Styled.Html (PagesMsg Msg))
getPostsHtml model =
    List.map
        (getPostHtml model)
        (List.filter
            (\comment ->
                case model.viewMode of
                    ViewAll ->
                        True

                    ViewApproved ->
                        comment.approved == 1

                    ViewRejected ->
                        comment.approved == 2

                    ViewPending ->
                        comment.approved == 0
            )
            model.comments
        )


getPostHtml : Model -> AdminComment -> Html.Styled.Html (PagesMsg Msg)
getPostHtml model comment =
    let
        view_html =
            [ div [] [ text ("Comment " ++ String.fromInt comment.id) ]
            , div [] [ text ("Member Id: " ++ String.fromInt comment.member_id) ]
            , div [] [ text ("Post: " ++ String.fromInt comment.post_id) ]
            , div [ css [ displayFlex ] ]
                [ text ("Remote Address: " ++ comment.remote_addr)
                , faButton theme.secondary (PagesMsg.fromMsg (ConfirmDeleteAll comment.remote_addr)) "fa-solid fa-dumpster"
                ]
            , div [] [ text ("Commented At: " ++ TimeUtils.toDateClock model.zone comment.commented_at) ]
            , div [] [ text ("Commented By: " ++ comment.commented_by) ]
            , div [] [ text ("Content: " ++ comment.content) ]
            , div []
                [ text
                    ("Approved: "
                        ++ (if comment.approved == 1 then
                                "true"

                            else if comment.approved == 2 then
                                "false"

                            else
                                "pending"
                           )
                    )
                ]
            ]
    in
    OWBTheme.card
        (List.foldr
            (::)
            [ br [] []
            , div [ css [ displayFlex, justifyContent spaceBetween ] ]
                [ div [ css [ displayFlex ] ]
                    [ faButton theme.primary (PagesMsg.fromMsg (ApproveComment comment)) "fa-solid fa-circle-check"
                    , faButton theme.secondary (PagesMsg.fromMsg (DisapproveComment comment)) "fa-solid fa-circle-xmark"
                    ]
                , div []
                    [ faButton theme.secondary (PagesMsg.fromMsg (ConfirmDelete comment.id)) "fa-solid fa-trash" ]
                ]
            ]
            view_html
        )


deleteConfirm : Model -> Html (PagesMsg Msg)
deleteConfirm model =
    let
        ( identity, deleteAction, deleteConfirmDisplay ) =
            case model.mode of
                DeleteAllConfirm ip ->
                    ( "comments from " ++ ip, DeleteAll ip, display block )

                DeleteConfirm id ->
                    ( "comment " ++ String.fromInt id, Delete id, display block )

                _ ->
                    ( "", CancelDelete, display none )
    in
    div [ css [ deleteConfirmDisplay ] ]
        [ div [ css [ textAlign left, maxWidth fitContent, margin auto ] ]
            [ text ("Are you sure you want to delete " ++ identity ++ "?")
            , br [] []
            , br [] []
            , div [ css [ displayFlex, justifyContent spaceAround ] ]
                [ faButton theme.secondary (PagesMsg.fromMsg CancelDelete) "fa-solid fa-ban"
                , faButton theme.primary (PagesMsg.fromMsg deleteAction) "fa-solid fa-save"
                ]
            ]
        ]


commentEncoder : AdminComment -> E.Value
commentEncoder comment =
    E.object
        [ ( "id", E.int comment.id )
        , ( "member_id", E.int comment.member_id )
        , ( "post_id", E.int comment.post_id )
        , ( "remote_addr", E.string comment.remote_addr )
        , ( "commented_by", E.string comment.commented_by )
        , ( "content", E.string comment.content )
        , ( "approved", E.int comment.approved )
        , ( "commented_at", E.int (Time.posixToMillis comment.commented_at) )
        ]


adminCommentDecoder : Decoder (List AdminComment)
adminCommentDecoder =
    D.list
        (D.map8 AdminComment
            (D.field "id" D.int)
            (D.field "member_id" D.int)
            (D.field "post_id" D.int)
            (D.field "remote_addr" D.string)
            (D.field "commented_at" (D.int |> andThen (\val -> succeed (Time.millisToPosix (val * 1000)))))
            (D.field "commented_by" D.string)
            (D.field "content" D.string)
            (D.field "approved" D.int)
        )
