module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html, div, text)
import Json.Decode as Decode exposing (Decoder)
import Markdown.Parser
import Markdown.Renderer
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


type alias BlogPostData =
    { body : String
    , title : String
    , tags : List String
    }


blogPost : BackendTask FatalError BlogPostData
blogPost =
    File.bodyWithFrontmatter blogPostDecoder
        "public/blog/hello-world.md"
        |> BackendTask.allowFatal


blogPostDecoder : String -> Decoder BlogPostData
blogPostDecoder body =
    Decode.map2 (BlogPostData body)
        (Decode.field "title" Decode.string)
        (Decode.field "tags" tagsDecoder)


tagsDecoder : Decoder (List String)
tagsDecoder =
    Decode.map (String.split " ")
        Decode.string


markdownToView :
    String
    -> Result String (List (Html msg))
markdownToView markdownString =
    markdownString
        |> Markdown.Parser.parse
        |> Result.mapError (\_ -> "Markdown error.")
        |> Result.andThen
            (\blocks ->
                Markdown.Renderer.render
                    Markdown.Renderer.defaultHtmlRenderer
                    blocks
            )


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    BackendTask.succeed
        [ { slug = "hello-world" }
        ]


type alias Data =
    { blogPostData : BlogPostData }


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    BackendTask.map Data
        blogPost


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
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
    -> View (PagesMsg Msg)
view app sharedModel =
    let
        renderedMarkdown =
            case markdownToView app.data.blogPostData.body of
                Ok html ->
                    html

                Err _ ->
                    [ div [] [ text "Error loading post..." ] ]
    in
    { title = "Placeholder - Blog.Slug_"
    , body = renderedMarkdown
    }
