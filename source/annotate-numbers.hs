#! /usr/bin/env nix-shell
#! nix-shell -i runhaskell -p
#! nix-shell "haskellPackages.ghcWithPackages (pkgs: with pkgs; [JuicyPixels JuicyPixels-util errors])"

import qualified Codec.Picture as P
import qualified Codec.Picture.RGBA8 as P8
import Data.Word (Word16)
import Data.List
import Debug.Trace
import Control.Error.Safe
import Safe (lastMay)
import Data.Maybe (catMaybes)
import System.Environment (getArgs)

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

imgDump :: Img -> [Int] -> [Int] -> String
imgDump img xs ys = unlines $ map showLine ys
  where showLine y = concatMap (\x -> if imgPixel img (x,y) then "#" else ".") xs

imgDumpFull :: Img -> String
imgDumpFull img = imgDump img [0..imgWidth img - 1] [0..imgHeight img - 1]

imgAllPixels :: Img -> [Coord]
imgAllPixels img = [(x, y) | x <- [0..imgWidth img - 1], y <- [0..imgHeight img - 1]]

--------------------------------------------------------------------------------
-- Number decoder

decodeNumber :: Img -> Coord -> Maybe (Integer, Size)
decodeNumber img (x, y) = do
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
       . : _ , - — black pixels
       #         — white pixels
       ?         — negativity bit
       +         — binary data
       :         — point (x, y)
  -}

  let px = imgPixel img

  -- 1. Check that 2x2 top left corner is empty (`.` and `:`)
  assertMay $ not $ any px [(x-1, y-1), (x, y-1), (x-1, y), (x,y)]

  -- 2. Calculate the size based on top and left edges (`.` and `#`)
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
    then (-number, (size, size+1))
    else (number, (size, size))

bitsToInteger :: [Bool] -> Integer
bitsToInteger = fst . foldl' f (0, 1)
  where
    f (sum, bit) True = (sum + bit, bit*2)
    f (sum, bit) False = (sum, bit*2)

--------------------------------------------------------------------------------
-- svg

svg img annotations =
  concat $ (
    svgHead img ++
    svgImgPoints img ++
    concatMap (\(x,y,w,h,text) -> svgAnnotation x y w h text) annotations ++
    ["</svg>"]
  )

svgHead img = [
    "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='",
    show $ imgWidth img * 8,
    "' height='",
    show $ imgHeight img * 8,
    "'>\n",
    "<rect width='100%' height='100%' style='fill:black'/>\n"
  ]

svgPoint img (x, y) = [
    "<rect x='", show (x*8),
    "' y='", show (y*8),
    "' width='7' height='7' style='fill:white'/>\n"
  ]

svgImgPoints img = 
  concatMap (svgPoint img) $ filter (imgPixel img) $ imgAllPixels img

svgAnnotation :: Double -> Double -> Double -> Double -> String -> [String]
svgAnnotation x y w h text = [
    "<rect x='", show (x*8),
    "' y='", show (y*8),
    "' width='", show (w*8),
    "' height='", show (h*8),
    "' style='fill:green;opacity:0.5'/>\n",

    "<text x='", show (x*8 + w*4),
    "' y='", show (y*8 + h*4),
    "' dominant-baseline='middle' text-anchor='middle' fill='white' style='",
    "paint-order: stroke; fill: white; stroke: black; stroke-width: 2px; font:24px bold sans;",
    "'>", text, "</text>\n"
  ]


--------------------------------------------------------------------------------
-- Main

decodeAnnotate img (x,y) = do
  (number, (w, h)) <- decodeNumber img (x, y)
  Just (fromIntegral x - 0.5, fromIntegral y - 0.5, fromIntegral w+2, fromIntegral h+2, show number)

annotateImg :: Img -> String
annotateImg img = svg img annotations
  where
    annotations = catMaybes $ map (decodeAnnotate img) $ imgAllPixels img

main = do
  [fnameIn, fnameOut] <- getArgs
  img <- imgLoad fnameIn 4
  writeFile fnameOut $ annotateImg img
