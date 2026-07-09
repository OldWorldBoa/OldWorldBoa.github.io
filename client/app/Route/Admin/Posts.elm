module Route.Admin.Posts exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Css exposing (auto, block, borderBox, boxSizing, center, display, displayFlex, fitContent, justifyContent, left, margin, marginTop, maxWidth, none, pct, px, spaceAround, spaceBetween, textAlign, width)
import Effect exposing (Effect(..))
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html.Styled exposing (Html, br, div, input, text, textarea)
import Html.Styled.Attributes exposing (css, rows, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
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
import TimeUtils exposing (fromInputDateTime, toInputDateTime)
import Url exposing (Protocol(..))
import UrlPath
import View exposing (View)


type alias Model =
    { zone : Time.Zone
    , mode : Mode
    , posts : List Post
    }


type alias Post =
    { id : Int
    , path : String
    , publish_time : Time.Posix
    , title : String
    , author : String
    , tags : String
    , preview : String
    }


type Mode
    = Edit Post
    | Delete Int
    | View


type Msg
    = AdjustTimeZone Time.Zone
    | ToggleEdit Post
    | ToggleDelete Int
    | ToggleView
    | ConfirmDelete Int
    | CreatePost
    | EditTitle String
    | EditAuthor String
    | EditPublishTime String
    | EditPreview String
    | EditTags String
    | EditPath String
    | EditSave
    | PostSaved (Result Http.Error (List Post))
    | GetPosts (Result Http.Error (List Post))


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init _ _ =
    ( Model Time.utc View []
    , Effect.batch
        [ Effect.fromCmd (Task.perform AdjustTimeZone Time.here)
        , Effect.fromCmd
            (Http.get
                { url = Settings.apiUrl ++ "/admin/posts/"
                , expect = Http.expectJson GetPosts postDecoder
                }
            )
        ]
    )


newPost : Post
newPost =
    Post 0 "" (Time.millisToPosix 2147483647000) "" "" "" ""


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

        CreatePost ->
            ( model
            , Effect.fromCmd
                (Http.post
                    { url = Settings.apiUrl ++ "/admin/post"
                    , body = Http.jsonBody (postEncoder newPost)
                    , expect = Http.expectJson PostSaved postDecoder
                    }
                )
            )

        ToggleEdit post ->
            case model.mode of
                Edit _ ->
                    ( { model | mode = View }, Effect.none )

                _ ->
                    ( { model | mode = Edit post }, Effect.none )

        ToggleView ->
            ( { model | mode = View }, Effect.none )

        ToggleDelete post_id ->
            case model.mode of
                Edit _ ->
                    ( { model | mode = View }, Effect.none )

                _ ->
                    ( { model | mode = Delete post_id }, Effect.none )

        ConfirmDelete id ->
            ( { model | mode = Delete id }, Effect.none )

        EditTitle title ->
            let
                oldDirtyPost =
                    case model.mode of
                        Edit post ->
                            post

                        _ ->
                            newPost

                newDirtyPost =
                    { oldDirtyPost | title = title }
            in
            ( { model | mode = Edit newDirtyPost }, Effect.none )

        EditAuthor author ->
            let
                oldDirtyPost =
                    case model.mode of
                        Edit post ->
                            post

                        _ ->
                            newPost

                newDirtyPost =
                    { oldDirtyPost | author = author }
            in
            ( { model | mode = Edit newDirtyPost }, Effect.none )

        EditPath path ->
            let
                oldDirtyPost =
                    case model.mode of
                        Edit post ->
                            post

                        _ ->
                            newPost

                newDirtyPost =
                    { oldDirtyPost | path = path }
            in
            ( { model | mode = Edit newDirtyPost }, Effect.none )

        EditPreview preview ->
            let
                oldDirtyPost =
                    case model.mode of
                        Edit post ->
                            post

                        _ ->
                            newPost

                newDirtyPost =
                    { oldDirtyPost | preview = preview }
            in
            ( { model | mode = Edit newDirtyPost }, Effect.none )

        EditTags tags ->
            let
                oldDirtyPost =
                    case model.mode of
                        Edit post ->
                            post

                        _ ->
                            newPost

                newDirtyPost =
                    { oldDirtyPost | tags = tags }
            in
            ( { model | mode = Edit newDirtyPost }, Effect.none )

        EditPublishTime time ->
            let
                publishTime =
                    fromInputDateTime time

                oldDirtyPost =
                    case model.mode of
                        Edit post ->
                            post

                        _ ->
                            newPost

                newDirtyPost =
                    { oldDirtyPost | publish_time = publishTime }
            in
            ( { model | mode = Edit newDirtyPost }, Effect.none )

        EditSave ->
            let
                saveCmd =
                    case model.mode of
                        Edit post ->
                            Http.request
                                { method = "PUT"
                                , headers = []
                                , url = Settings.apiUrl ++ "/admin/post/" ++ String.fromInt post.id
                                , body = Http.jsonBody (postEncoder post)
                                , expect = Http.expectJson PostSaved postDecoder
                                , timeout = Nothing
                                , tracker = Nothing
                                }

                        _ ->
                            Cmd.none
            in
            ( { model | mode = View }
            , Effect.fromCmd
                saveCmd
            )

        PostSaved response ->
            case response of
                Ok posts ->
                    ( { model | posts = posts }, Effect.none )

                Err _ ->
                    ( model, Effect.none )

        GetPosts response ->
            case response of
                Ok posts ->
                    ( { model | posts = posts }, Effect.none )

                Err _ ->
                    ( model, Effect.none )


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
    { title = "Post Admin"
    , body =
        [ Html.Styled.toUnstyled
            (div []
                (List.append
                    [ br [] []
                    , div [ css [ margin auto, width (pct 100), textAlign center ] ]
                        [ OWBTheme.btn [ onClick (PagesMsg.fromMsg CreatePost) ] [ text "New Post" ]
                        ]
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
        model.posts


getPostHtml : Model -> Post -> Html.Styled.Html (PagesMsg Msg)
getPostHtml model post =
    let
        view_html =
            [ div [] [ text ("Post " ++ String.fromInt post.id) ]
            , div [] [ text ("Title: " ++ post.title) ]
            , div [] [ text ("Path: " ++ post.path) ]
            , div [] [ text ("Author: " ++ post.author) ]
            , div [] [ text ("Publish Time: " ++ TimeUtils.toDateClock model.zone post.publish_time) ]
            , div [] [ text ("Tags: " ++ post.tags) ]
            , div [] [ text ("Preview Text: " ++ post.preview) ]
            ]

        info =
            case model.mode of
                Edit editPost ->
                    if editPost.id == post.id then
                        [ div [] [ text ("Post " ++ String.fromInt editPost.id) ]
                        , div []
                            [ text "Title: "
                            , input
                                [ type_ "text"
                                , value editPost.title
                                , onInput (\s -> PagesMsg.fromMsg (EditTitle s))
                                ]
                                []
                            ]
                        , div []
                            [ text "Path: "
                            , input
                                [ type_ "text"
                                , value editPost.path
                                , onInput (\s -> PagesMsg.fromMsg (EditPath s))
                                ]
                                []
                            ]
                        , div []
                            [ text "Author: "
                            , input
                                [ type_ "text"
                                , value editPost.author
                                , onInput (\s -> PagesMsg.fromMsg (EditAuthor s))
                                ]
                                []
                            ]
                        , div []
                            [ text "Publish Time: "
                            , input
                                [ type_ "datetime-local"
                                , value (toInputDateTime model.zone editPost.publish_time)
                                , onInput (\s -> PagesMsg.fromMsg (EditPublishTime s))
                                ]
                                []
                            ]
                        , div []
                            [ text "Tags: "
                            , input
                                [ type_ "text"
                                , value editPost.tags
                                , onInput (\s -> PagesMsg.fromMsg (EditTags s))
                                ]
                                []
                            ]
                        , div []
                            [ text "Preview Text: "
                            , br [] []
                            , div [ css [ width (pct 100), margin auto ] ]
                                [ textarea
                                    [ rows 4
                                    , value editPost.preview
                                    , onInput (\s -> PagesMsg.fromMsg (EditPreview s))
                                    , css [ width (pct 100), boxSizing borderBox ]
                                    ]
                                    []
                                ]
                            ]
                        , div [ css [ displayFlex, marginTop (px 5) ] ]
                            [ div []
                                [ faButton
                                    theme.secondary
                                    (PagesMsg.fromMsg (ToggleEdit post))
                                    "fa-solid fa-cancel"
                                ]
                            , div []
                                [ faButton
                                    theme.primary
                                    (PagesMsg.fromMsg EditSave)
                                    "fa-solid fa-save"
                                ]
                            ]
                        ]

                    else
                        view_html

                _ ->
                    view_html
    in
    OWBTheme.card
        (List.foldr
            (::)
            [ br [] []
            , div [] [ text "Preview:" ]
            , OWBTheme.getPostHtml model.zone post
            , div [ css [ displayFlex, justifyContent spaceBetween ] ]
                [ div []
                    [ faButton theme.primary (PagesMsg.fromMsg (ToggleEdit post)) "fa-solid fa-edit" ]
                , div []
                    [ faButton theme.secondary (PagesMsg.fromMsg (ConfirmDelete post.id)) "fa-solid fa-trash" ]
                ]
            ]
            info
        )


deleteConfirm : Model -> Html (PagesMsg Msg)
deleteConfirm model =
    let
        ( post_to_del, deleteConfirmDisplay ) =
            case model.mode of
                Delete post_id ->
                    ( post_id, display block )

                _ ->
                    ( 0, display none )
    in
    div [ css [ deleteConfirmDisplay ] ]
        [ div [ css [ textAlign left, maxWidth fitContent, margin auto ] ]
            [ text ("Are you sure you want to delete post " ++ String.fromInt post_to_del ++ "?")
            , br [] []
            , br [] []
            , div [ css [ displayFlex, justifyContent spaceAround ] ]
                [ faButton theme.secondary (PagesMsg.fromMsg ToggleView) "fa-solid fa-ban"
                , faButton theme.primary (PagesMsg.fromMsg (ConfirmDelete post_to_del)) "fa-solid fa-save"
                ]
            ]
        ]


postEncoder : Post -> E.Value
postEncoder post =
    E.object
        [ ( "id", E.int post.id )
        , ( "path", E.string post.path )
        , ( "title", E.string post.title )
        , ( "author", E.string post.author )
        , ( "tags", E.string post.tags )
        , ( "preview", E.string post.preview )
        , ( "publish_time", E.int (Time.posixToMillis post.publish_time) )
        ]


postDecoder : Decoder (List Post)
postDecoder =
    D.list
        (D.map7 Post
            (D.field "id" D.int)
            (D.field "path" D.string)
            (D.field "publish_time" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
            (D.field "title" D.string)
            (D.field "author" D.string)
            (D.field "tags" D.string)
            (D.field "preview" D.string)
        )
