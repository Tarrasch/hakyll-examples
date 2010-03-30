module Main where

import Text.Hakyll (hakyll)
import Text.Hakyll.Render
import Text.Hakyll.Context
import Text.Hakyll.File (getRecursiveContents, directory)
import Text.Hakyll.CreateContext (createPage, createCustomPage, createListing)
import Data.List (sort)
import Control.Monad (forM_, liftM)
import Control.Monad.Reader (liftIO)
import Data.Either (Either(..))

main = hakyll "http://example.com" $ do
    -- Static directory.
    directory css "css"

    -- Find all post paths.
    postPaths <- liftM (reverse . sort) $ getRecursiveContents "posts"
    let postPages = map createPage postPaths

    -- Render index, including recent posts.
    let index = createListing "index.html" ["templates/postitem.html"]
                              (take 3 postPages) [("title", Left "Home")]
    renderChain ["index.html", "templates/default.html"] index

    -- Render all posts list.
    let posts = createListing "posts.html" ["templates/postitem.html"]
                              postPages [("title", Left "All posts")]
    renderChain ["posts.html", "templates/default.html"] posts

    -- Render all posts.
    liftIO $ putStrLn "Generating posts..."
    forM_ postPages $ renderChain [ "templates/post.html"
                                  , "templates/default.html"
                                  ]
