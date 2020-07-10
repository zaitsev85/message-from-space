#! /usr/bin/env nix-shell
-- Usage: ./annotate.hs in-msg.png out-annotated.svg out-decoded.txt
#! nix-shell -i runhaskell -p
#! nix-shell "haskellPackages.ghcWithPackages (pkgs: with pkgs; [JuicyPixels JuicyPixels-util errors extra groupBy])"
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/5cb5ccb54229efd9a4cd1fccc0f43e0bbed81c5d.tar.gz

import Control.Applicative ((<|>))
import Control.Error.Safe (assertMay)
import Data.List (foldl', intercalate)
import Data.List.Extra (groupOn)
import Data.List.GroupBy (groupBy)
import Data.Maybe (catMaybes)
import Data.Word (Word16)
import Safe (lastMay)
import System.Environment (getArgs)
import qualified Codec.Picture as P
import qualified Codec.Picture.RGBA8 as P8

--------------------------------------------------------------------------------
-- Img

type Scale = Int
type Coord = (Int, Int)
type Size = (Int, Int)
data Img = Img (P.Image P.PixelRGBA8) Scale

imgLoad :: FilePath -> Scale -> IO Img
imgLoad path scale = (\img -> Img img scale) <$> P8.readImageRGBA8 path

imgWidth :: Img -> Int
imgWidth (Img img scale) = P.imageWidth img `div` scale

imgHeight :: Img -> Int
imgHeight (Img img scale) = P.imageHeight img `div` scale

imgPixel :: Img -> Coord -> Bool
imgPixel (Img img scale) (x, y) =
  if x' < 0 || y' < 0 || x' >= P.imageWidth img || y' >= P.imageHeight img
  then False
  else fromIntegral r + fromIntegral g + fromIntegral b > (0::Word16)
  where
    x' = x * scale
    y' = y * scale
    P.PixelRGBA8 r g b _ = P.pixelAt img x' y'

imgShow :: Img -> [Int] -> [Int] -> String
imgShow img xs ys = unlines $ map showLine ys
  where showLine y = concatMap (\x -> if imgPixel img (x,y) then "#" else ".") xs

imgShowFull :: Img -> String
imgShowFull img = imgShow img [0..imgWidth img - 1] [0..imgHeight img - 1]

instance Show Img where
  show = imgShowFull

imgAllPixels :: Img -> [Coord]
imgAllPixels img = [(x, y) | y <- [0..imgHeight img - 1], x <- [0..imgWidth img - 1]]

imgInnerPixels :: Img -> [Coord]
imgInnerPixels img = [(x, y) | y <- [1..imgHeight img - 2], x <- [1..imgWidth img - 2]]

--------------------------------------------------------------------------------
-- Number decoder

decodeSymbol :: Img -> Coord -> Maybe (Integer, Bool, Size)
decodeSymbol img (x, y) = do
  {-
    Figure:
       . . _ _ _ _ ,
       . : # # # # ,   → x
       _ # + + + + -
       _ # + + + + -
       _ # + + + + -
       _ # + + + + -
       , ? - - - - -

         ↓
         y

     Legend:
       . _ , - — black pixels
       #       — white pixels
       ?       — negativity bit
       +       — binary data
       :       — point (x, y). isOperator bit
  -}

  let px = imgPixel img

  -- 1. Check that top left corner is empty (`.`)
  assertMay $ not $ any px [(x-1, y-1), (x, y-1), (x-1, y)]

  let isOperator = px (x, y)

  -- 2. Calculate the size based on top and left edges (`_` and `#`)
  let topLeft' i = (px (x + i, y - 1), px (x + i, y),
                    px (x - 1, y + i), px (x,     y + i))
  let topLeft = takeWhile (\i -> (False, True, False, True) == topLeft' i) $ [1..]
  size <- lastMay topLeft
  assertMay $ size >= 1

  -- 3. Check the negativity bit (`?`) and empty space at corners (`,`)
  negative <-
    case topLeft' (size+1) of
      (False, False, False, False) -> Just False
      (False, False, False, True) -> Just True
      otherwise -> Nothing

  -- 4. Check that right and bottom edges are empty (`-`)
  assertMay $ not $
    any (\i -> px (x + size + 1, y+i) || px(x+i, y + size + 1)) [1 .. size+1]

  -- 5. Decode binary data
  let number = bitsToInteger [px (ix,iy) | iy <- [y+1 .. y+size], ix <- [x+1 .. x+size]]

  Just $ if negative
    then (-number, isOperator, (size+1, size+2))
    else (number, isOperator, (size+1, size+1))

bitsToInteger :: [Bool] -> Integer
bitsToInteger = fst . foldl' f (0, 1)
  where
    f (sum, bit) True = (sum + bit, bit*2)
    f (sum, bit) False = (sum, bit*2)

sym :: [String] -> [[Bool]]
sym = map (map (=='#'))

symEllipsis = sym
  [ "........."
  , ".#.#.#.#."
  , "........."
  ]

checkLine :: Img -> [Bool] -> Coord -> Bool
checkLine img [] _ = True
checkLine img (h:t) (x, y) = (imgPixel img (x, y) == h) && checkLine img t (x+1, y)

checkSymbol :: Img -> [[Bool]] -> Coord -> Bool
checkSymbol _ [] _ = True
checkSymbol img (h:t) (x, y) = checkLine img h (x, y) && checkSymbol img t (x, y+1)

--------------------------------------------------------------------------------
-- svg

svg img annotations =
  concat $ (
    svgHead img ++
    svgImgPoints img ++
    concatMap (\(coord,size,text,color) -> svgAnnotation coord size text color) annotations ++
    ["</svg>"]
  )

svgHead img = [
    "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='",
    show $ 1 + imgWidth img * 8,
    "' height='",
    show $ 1 + imgHeight img * 8,
    "'>\n",
    "<rect width='100%' height='100%' style='fill:black'/>\n"
  ]

svgPoint img (x, y) value = [
    "<rect x='", show (1 + x*8),
    "' y='", show (1 + y*8),
    "' width='7' height='7' style='fill:",
    if value then "white" else "#333333",
    "'/>\n"
  ]

svgImgPoints img =
  concatMap (\coord -> svgPoint img coord (imgPixel img coord)) $ imgAllPixels img

svgAnnotation :: Coord -> Size -> String -> String -> [String]
svgAnnotation (x, y) (w, h) text color = [
    "<rect x='", show (1 + x*8 - 6),
    "' y='", show (1 + y*8 - 6),
    "' width='", show (w*8 + 11),
    "' height='", show (h*8 + 11),
    "' style='fill:", color, ";opacity:0.5'/>\n",

    "<text x='", show (1 + x*8 + w*4),
    "' y='", show (1 + y*8 + h*4),
    "' dominant-baseline='middle' text-anchor='middle' fill='white' style='",
    "paint-order: stroke; fill: white; stroke: black; stroke-width: 2px; font:24px bold sans;",
    "'>", text, "</text>\n"
  ]

--------------------------------------------------------------------------------
-- Main

decodeAnnotate img coord@(x,y) = num <|> symEllipsis'
  where
    num = do
      (value, isOperator, size) <- decodeSymbol img (x, y)
      Just $ if isOperator
      then (coord, size, showOperator value, "yellow")
      else (coord, size, show value, "green")
    
    showOperator 0 = "ap"
    showOperator 12 = "="
    showOperator 401 = "dec"
    showOperator 417 = "inc"
    showOperator 365 = "add"

    -- TODO: proper way of detecting of variables
    showOperator 501 = "x0"
    showOperator 485 = "x1"
    showOperator 65193 = "x2"
    showOperator 65161 = "x3"
    showOperator 64745 = "x4"

    showOperator n = ":" ++ show n

    symEllipsis' = do
      assertMay $ checkSymbol img symEllipsis (x, y)
      Just ((x+1, y+1), (7, 1), "...", "gray")

annotateImg :: Img -> String
annotateImg img = id
  $ svg img
  $ catMaybes
  $ map (decodeAnnotate img)
  $ imgInnerPixels img

decodeImg :: Img -> String
decodeImg img = id
    $ unlines
    $ map (intercalate "   ") -- join groups
    $ map (map (intercalate " ")) -- join items inside each group
    $ map (map (map (\(_,_,text,_) -> text)))
    $ map (groupBy (\a b -> xRight a >= xLeft b - 2)) -- split by horisontal groups
    $ groupOn (\((_,y),_,_,_) -> y) -- split by lines
    $ catMaybes
    $ map (decodeAnnotate img)
    $ imgInnerPixels img
  where
    xLeft ((x,_),(_,_),_,_) = x
    xRight ((x,_),(w,_),_,_) = x + w

main = do
  [fnameIn, fnameSvg, fnameTxt] <- getArgs
  img <- imgLoad fnameIn 4
  writeFile fnameSvg $ annotateImg img
  writeFile fnameTxt $ decodeImg img
