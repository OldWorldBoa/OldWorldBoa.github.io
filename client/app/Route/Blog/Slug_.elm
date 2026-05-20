port module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (div, pre, text)
import Html.Attributes exposing (class)
import Markdown.Block exposing (Block(..), Html(..), Inline(..))
import Markdown.Parser
import Markdown.Renderer
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Server.Request exposing (Request)
import Server.Response
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


type alias Data =
    { body : String }


type alias ActionData =
    {}


port initializeMermaid : () -> Cmd msg


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.serverRender
        { action = \_ _ -> BackendTask.succeed (Server.Response.render {})
        , head = head
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , subscriptions = \_ _ _ _ -> Sub.none
            , update = \_ _ _ _ -> ( {}, Effect.fromCmd (initializeMermaid ()) )
            , init = \_ _ -> ( {}, Effect.fromCmd (initializeMermaid ()) )
            }


data :
    RouteParams
    -> Request
    -> BackendTask FatalError (Server.Response.Response Data ErrorPage)
data routeParams _ =
    BackendTask.map
        Server.Response.render
        (BackendTask.map Data
            (blogPost routeParams)
        )


blogPost : RouteParams -> BackendTask FatalError String
blogPost routeParams =
    File.bodyWithoutFrontmatter
        ("public/blog/"
            ++ routeParams.slug
            ++ ".md"
        )
        |> BackendTask.allowFatal


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app _ _ =
    let
        renderedMarkdown =
            case markdownToView app.data.body of
                Ok html ->
                    html

                Err _ ->
                    [ div [] [ text "Error loading post..." ] ]
    in
    { title = "Title"
    , body = renderedMarkdown
    }


markdownToView :
    String
    -> Result String (List (Html.Html msg))
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
                    [ div [] [ text "failed..." ] ]
    in
    case block of
        CodeBlock code ->
            case code.language of
                Just lang ->
                    if lang == "mermaid" then
                        [ pre [ class "mermaid" ]
                            [ text code.body ]
                        ]

                    else
                        rendered

                Nothing ->
                    rendered

        _ ->
            rendered
