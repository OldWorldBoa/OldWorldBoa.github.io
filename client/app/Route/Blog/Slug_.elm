module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Http
import Css exposing (block, center, display, displayFlex, justifyContent, none, textAlign)
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Html.Styled exposing (br, div, h1, hr, text)
import Html.Styled.Attributes exposing (css, rows, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Json.Decode as D exposing (Decoder, andThen, succeed)
import Json.Encode as E
import Markdown.Block exposing (Block(..), Html(..), Inline(..))
import Markdown.Parser
import Markdown.Renderer
import OWBTheme
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App)
import Server.Request exposing (Request)
import Server.Response
import Settings
import Shared
import Task
import Time
import TimeUtils
import View exposing (View)


type alias Model =
    { comments : List Comment
    , zone : Time.Zone
    , newComment : NewComment
    , mode : ViewMode
    }


type ViewMode
    = View
    | InputComment
    | CommentThanks


type Msg
    = AdjustTimeZone Time.Zone
    | GetComments (Result Http.Error (List Comment))
    | AddComment
    | OpenInputComment
    | EditFrom String
    | EditMessage String


type alias RouteParams =
    { slug : String }


type alias Data =
    { body : String
    , info : PostInfo
    }


type alias ActionData =
    {}


type alias PostInfo =
    { id : Int
    , path : String
    , publish_time : Time.Posix
    , title : String
    , author : String
    , tags : String
    , preview : String
    }


type alias Comment =
    { commented_at : Time.Posix
    , commented_by : String
    , content : String
    }


type alias NewComment =
    { member_id : Int
    , commented_by : String
    , content : String
    }


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.serverRender
        { action = \_ _ -> BackendTask.succeed (Server.Response.render {})
        , head = head
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , subscriptions = \_ _ _ _ -> Sub.none
            , update = update
            , init = init
            }


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init app _ =
    ( Model [] Time.utc (NewComment 1 "" "") View
    , Effect.batch
        [ Effect.fromCmd (Task.perform AdjustTimeZone Time.here)
        , Effect.fromCmd
            (Http.get
                { url = Settings.apiUrl ++ "/post/" ++ String.fromInt app.data.info.id ++ "/comments/"
                , expect = Http.expectJson GetComments commentDecoder
                }
            )
        ]
    )


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update app _ msg model =
    case msg of
        AdjustTimeZone zone ->
            ( { model | zone = zone }, Effect.none )

        GetComments response ->
            case response of
                Ok comments ->
                    ( { model | comments = comments }, Effect.none )

                Err _ ->
                    ( model, Effect.none )

        OpenInputComment ->
            ( { model | mode = InputComment }, Effect.none )

        AddComment ->
            ( { model | newComment = NewComment 1 "" "", mode = CommentThanks }
            , Effect.fromCmd
                (Http.post
                    { url = Settings.apiUrl ++ "/post/" ++ String.fromInt app.data.info.id ++ "/comment/"
                    , body = Http.jsonBody (newCommentEncoder model.newComment)
                    , expect = Http.expectJson GetComments commentDecoder
                    }
                )
            )

        EditFrom from ->
            let
                oldComment =
                    model.newComment

                newComment =
                    { oldComment | commented_by = from }
            in
            ( { model | newComment = newComment }, Effect.none )

        EditMessage message ->
            let
                oldComment =
                    model.newComment

                newComment =
                    { oldComment | content = message }
            in
            ( { model | newComment = newComment }, Effect.none )


data :
    RouteParams
    -> Request
    -> BackendTask FatalError (Server.Response.Response Data ErrorPage)
data routeParams _ =
    BackendTask.map
        Server.Response.render
        (BackendTask.map2 Data
            (postContent routeParams)
            (postInfo routeParams)
        )


postContent : RouteParams -> BackendTask FatalError String
postContent routeParams =
    File.bodyWithoutFrontmatter
        ("public/blog/"
            ++ routeParams.slug
            ++ ".md"
        )
        |> BackendTask.allowFatal


postInfo : RouteParams -> BackendTask FatalError PostInfo
postInfo routeParams =
    BackendTask.Http.get
        (Settings.apiUrl ++ "/post/" ++ routeParams.slug)
        (BackendTask.Http.expectJson postDecoder)
        |> BackendTask.allowFatal


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "the-byte-station"
        , image =
            { url = Pages.Url.external ("https://the-byte-station.ca/blog" ++ app.data.info.path)
            , alt = "the-byte-station logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = app.data.info.preview
        , locale = Nothing
        , title = app.data.info.title
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app _ model =
    let
        renderedMarkdown =
            case markdownToView app.data.body of
                Ok html ->
                    html

                Err _ ->
                    [ Html.Styled.toUnstyled (div [] [ text "Error loading post..." ]) ]
    in
    { title = app.data.info.title
    , body =
        List.foldr
            (::)
            [ Html.Styled.toUnstyled
                (div
                    []
                    [ addCommentsHtml model
                    , getCommentsHtml model
                    ]
                )
            ]
            renderedMarkdown
    }


markdownToView :
    String
    -> Result String (List (Html.Html (PagesMsg Msg)))
markdownToView markdownString =
    markdownString
        |> Markdown.Parser.parse
        |> Result.mapError (\_ -> "Markdown error.")
        |> Result.andThen
            (\blocks ->
                Ok
                    (List.foldr
                        (++)
                        []
                        (List.map
                            render
                            blocks
                        )
                    )
            )


addCommentsHtml : Model -> Html.Styled.Html (PagesMsg Msg)
addCommentsHtml model =
    let
        displayAdd =
            case model.mode of
                InputComment ->
                    display block

                _ ->
                    display none
    in
    div []
        [ br [] []
        , OWBTheme.spacer
        , div
            []
            [ h1 [ css [ displayFlex, justifyContent center ] ]
                [ text "Comments"
                , OWBTheme.faButton OWBTheme.theme.primary (PagesMsg.fromMsg OpenInputComment) "fa-solid fa-comment-medical"
                ]
            ]
        , commentsThanksHtml model
        , div [ css [ displayAdd ] ]
            [ OWBTheme.card
                [ text "From"
                , OWBTheme.styledInput
                    [ css []
                    , type_ "text"
                    , value model.newComment.commented_by
                    , onInput (\s -> PagesMsg.fromMsg (EditFrom s))
                    ]
                    []
                , br [] []
                , br [] []
                , text "Message"
                , OWBTheme.styledTextarea
                    [ onInput (\s -> PagesMsg.fromMsg (EditMessage s))
                    , value model.newComment.content
                    , rows 5
                    ]
                , br [] []
                , br [] []
                , OWBTheme.btn [ onClick (PagesMsg.fromMsg AddComment) ] [ text "Send" ]
                ]
            ]
        ]


commentsThanksHtml : Model -> Html.Styled.Html (PagesMsg Msg)
commentsThanksHtml model =
    let
        displayThanks =
            case model.mode of
                CommentThanks ->
                    display block

                _ ->
                    display none
    in
    div [ css [ displayThanks, textAlign center ] ]
        [ text "Thanks for the comment! Your comment will show up once a moderator approves it." ]


getCommentsHtml : Model -> Html.Styled.Html (PagesMsg Msg)
getCommentsHtml model =
    div []
        (List.map
            (getCommentHtml model)
            model.comments
        )


getCommentHtml : Model -> Comment -> Html.Styled.Html (PagesMsg Msg)
getCommentHtml model comment =
    OWBTheme.card
        [ div []
            [ text (comment.commented_by ++ " - ")
            , text (TimeUtils.toDateClock model.zone comment.commented_at)
            ]
        , hr [] []
        , div [] [ text comment.content ]
        ]


render : Block -> List (Html.Html msg)
render block =
    let
        rendered_result =
            Markdown.Renderer.render
                Markdown.Renderer.defaultHtmlRenderer
                [ block ]

        rendered =
            case rendered_result of
                Ok result ->
                    result

                _ ->
                    [ Html.Styled.toUnstyled (div [] [ text "failed..." ]) ]
    in
    rendered


postDecoder : Decoder PostInfo
postDecoder =
    D.map7 PostInfo
        (D.field "id" D.int)
        (D.field "path" D.string)
        (D.field "publish_time" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
        (D.field "title" D.string)
        (D.field "author" D.string)
        (D.field "tags" D.string)
        (D.field "preview" D.string)


commentDecoder : Decoder (List Comment)
commentDecoder =
    D.list
        (D.map3 Comment
            (D.field "commented_at" (D.int |> andThen (\val -> succeed (Time.millisToPosix (val * 1000)))))
            (D.field "commented_by" D.string)
            (D.field "content" D.string)
        )


newCommentEncoder : NewComment -> E.Value
newCommentEncoder comment =
    E.object
        [ ( "commented_by", E.string comment.commented_by )
        , ( "content", E.string comment.content )
        , ( "member_id", E.int comment.member_id )
        ]
