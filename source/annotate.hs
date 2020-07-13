#! /usr/bin/env nix-shell
-- Usage: ./annotate.hs in-msg.png out-annotated.svg out-decoded.txt
#! nix-shell -i runhaskell -p
#! nix-shell "haskellPackages.ghcWithPackages (pkgs: with pkgs; [JuicyPixels JuicyPixels-util errors extra groupBy])"
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/5cb5ccb54229efd9a4cd1fccc0f43e0bbed81c5d.tar.gz

import Control.Arrow ((&&&))
import Control.Error.Safe (justZ)
import Control.Monad (forM, forM_, guard)
import Control.Monad.ST (runST)
import Control.Monad.Trans (lift)
import Control.Monad.Trans.Maybe (runMaybeT)
import Data.List (foldl', intercalate, sortOn)
import Data.List.GroupBy (groupBy)
import Data.Maybe (catMaybes, fromMaybe)
import Data.Word (Word16)
import System.Environment (getArgs)
import qualified Codec.Picture as P
import qualified Codec.Picture.RGBA8 as P8
import qualified Data.Vector.Mutable as V

--------------------------------------------------------------------------------
-- Types

type Scale = Int
type Coord = (Int, Int)
type Size = (Int, Int)

data Img = Img (P.Image P.PixelRGBA8) Scale

data Symbol
  = SymNumber Integer
  | SymOperator Integer
  | SymVariable Integer
  | SymEllipsis
  | SymUnknown

--------------------------------------------------------------------------------
-- Misc functions

range2d :: Int -> Int -> Int -> Int -> [(Int, Int)]
range2d x0 y0 x1 y1 = [(x', y') | y' <- [y0 .. y1], x' <- [x0 .. x1]]

none :: (a -> Bool) -> [a] -> Bool
none = (not .) . any

bitsToInteger :: [Bool] -> Integer
bitsToInteger = fst . foldl' f (0, 1)
  where
    f (sum, bit) True = (sum + bit, bit*2)
    f (sum, bit) False = (sum, bit*2)

groupAcc :: (a -> s) -> (s -> a -> Maybe s) -> [a] -> [(s, [a])]
groupAcc init f = groupAcc1'
  where
    groupAcc1' [] = []
    groupAcc1' (x:xs) = takeGroup (init x) [x] xs

    takeGroup state group [] = [(state, reverse group)]
    takeGroup state group (y:ys) = case f state y of
      Nothing -> (state, reverse group) : groupAcc1' (y:ys)
      Just state' -> takeGroup state' (y : group) ys

--------------------------------------------------------------------------------
-- Img

imgLoad :: FilePath -> Scale -> IO Img
imgLoad path scale = (\img -> Img img scale) <$> P8.readImageRGBA8 path

imgWidth :: Img -> Int
imgWidth (Img img scale) = P.imageWidth img `div` scale

imgHeight :: Img -> Int
imgHeight (Img img scale) = P.imageHeight img `div` scale

imgPixel :: Img -> Coord -> Bool
imgPixel (Img img scale) (x, y) = True
  && x' >= 0 && y' >= 0
  && x' < P.imageWidth img && y' < P.imageHeight img
  && fromIntegral r + fromIntegral g + fromIntegral b > (0::Word16)
  where
    (x', y') = (x * scale, y * scale)
    P.PixelRGBA8 r g b _ = P.pixelAt img x' y'

imgShow :: Img -> [Int] -> [Int] -> String
imgShow img xs ys = unlines $ map showLine ys
  where showLine y = map (\x -> if imgPixel img (x, y) then '#' else '.') xs

imgShowFull :: Img -> String
imgShowFull img = imgShow img [0 .. imgWidth img - 1] [0 .. imgHeight img - 1]

instance Show Img where
  show = imgShowFull

imgAllPixels :: Img -> [Coord]
imgAllPixels img = range2d 0 0 (imgWidth img - 1) (imgHeight img - 1)

--------------------------------------------------------------------------------
-- Symbol decoder

symDecode :: Img -> Coord -> Size -> Symbol
symDecode img (x, y) (w, h)
  | isNonNegativeNumber = SymNumber value
  | isNegativeNumber = SymNumber (-value)
  | isVariable = SymVariable varValue
  | isOperator = SymOperator value
  | isEllipsis = SymEllipsis
  | otherwise = SymUnknown
  where
    size = w

    px (x', y') = imgPixel img (x + x', y + y')

    isNonNegativeNumber = True
      && w == h
      && not (px (0, 0))

    isNegativeNumber = True
      && w + 1 == h
      && not (px (0, 0))
      && px (0, size)
      && none px [(x', size) | x' <- [1 .. size-1]] -- bottom + 1 is empty

    isOperator = True
      && w == h
      && px (0, 0)

    isVariable = True
      && w == h
      && px (1, 1)
      && all px [(x',     size-1) | x' <- [0 .. size-1]] -- bottom is full
      && all px [(size-1, y')     | y' <- [0 .. size-1]] -- right is full
      && none px [(x', 1) | x' <- [2 .. size-2]] -- top + 1 is empty
      && none px [(1, y') | y' <- [2 .. size-2]] -- left + 1 is empty

    isEllipsis = checkSymbol img symEllipsis (x-1, y-1)

    value = bitsToInteger $ map px $ range2d 1 1 (size-1) (size-1)

    varValue = bitsToInteger $ map (not . px) $ range2d 2 2 (size-2) (size-2)

symDetectAll :: Img -> [(Coord, Size)]
symDetectAll img = runST $ do
  vec <- V.replicate (width * height) False
  fmap catMaybes $ forM validRange $ \(x, y) -> runMaybeT $ do
    guard =<< not <$> V.read vec (idx (x, y))
    (w, h) <- justZ $ symDetectSingle img (x, y)
    lift $ forM_ (range2d x y (x+w-1) (y+h-1)) $ flip (V.write vec) True . idx
    return ((x, y), (w, h))
  where
    (width, height) = (imgWidth &&& imgHeight) img
    validRange = range2d 2 2 (width - 3) (height - 3)
    idx (x, y) = x + y * width

symDetectSingle :: Img -> Coord -> Maybe Size
symDetectSingle img (x, y)
  | px 1 0 && px 0 1 = Just (width + 1, height + 1)
  | checkSymbol img symEllipsis (x-1, y-1) = Just (7, 1)
  | otherwise = Nothing
  where
    px x' y' = imgPixel img (x + x', y + y')
    width = length $ takeWhile (flip px 0) [1 ..]
    height = length $ takeWhile (px 0) [1 ..]

symEllipsis :: [[Bool]]
symEllipsis = map (map (=='#'))
  [ "........."
  , ".#.#.#.#."
  , "........."
  ]

checkLine :: Img -> [Bool] -> Coord -> Bool
checkLine _ [] _ = True
checkLine img (h:t) (x, y) = (imgPixel img (x, y) == h) && checkLine img t (x+1, y)

checkSymbol :: Img -> [[Bool]] -> Coord -> Bool
checkSymbol _ [] _ = True
checkSymbol img (h:t) (x, y) = checkLine img h (x, y) && checkSymbol img t (x, y+1)

--------------------------------------------------------------------------------
-- svg

svg :: Img -> [(Coord, Size, String, String)] -> String
svg img annotations =
  concat (
    svgHead img ++
    svgImgPoints img ++
    concatMap (\(coord, size, text, color) -> svgAnnotation coord size text color) annotations ++
    ["</svg>"]
  )

svgHead :: Img -> [String]
svgHead img = [
    "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='",
    show $ 1 + imgWidth img * 8,
    "' height='",
    show $ 1 + imgHeight img * 8,
    "'>\n",
    "<rect width='100%' height='100%' style='fill:black'/>\n"
  ]

svgPoint :: Coord -> Bool -> [String]
svgPoint (x, y) value = [
    "<rect x='", show (1 + x*8),
    "' y='", show (1 + y*8),
    "' width='7' height='7' style='fill:",
    if value then "white" else "#333333",
    "'/>\n"
  ]

svgImgPoints :: Img -> [String]
svgImgPoints img =
  concatMap (\coord -> svgPoint coord (imgPixel img coord)) $ imgAllPixels img

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

annotateImg :: Img -> String
annotateImg img = id
  $ svg img
  $ map (symRepr' img)
  $ symDetectAll img

decodeImg :: Img -> String
decodeImg img = id
    $ unlines
    $ map (intercalate "   ") -- join groups
    $ map (map (intercalate " ")) -- join items inside each group
    $ map (map (map (\(_, _, text, _) -> text)))
    $ map (groupBy (\a b -> xRight a >= xLeft b - 2)) -- split by horisontal groups
    $ splitByLines
    $ map (symRepr' img)
    $ symDetectAll img
  where
    xLeft ((x, _), _, _, _) = x
    xRight ((x, _), (w, _), _, _) = x + w

splitByLines :: [(Coord, Size, a, b)] -> [[(Coord, Size, a, b)]]
splitByLines = id
  . map (sortOn (\((x, _), _, _, _) -> x))
  . map concat
  . map (map snd . snd) -- drop accumulators from both groupAcc's
  . groupAcc fst (\s x -> addRanges s (fst x))
  . groupAcc yRange (\s x -> addRanges s (yRange x))
  where
    yRange ((_, y), (_, h), _, _) = (y, y+h)
    addRanges (a0, a1) (b0, b1)
      | b0 <= a0 && a0 <= b1 = Just (b0, max a1 b1)
      | a0 <= b0 && b0 <= a1 = Just (a0, max a1 b1)
      | otherwise = Nothing

symRepr :: Symbol -> (String, String)
symRepr SymUnknown = ("?", "gray")
symRepr SymEllipsis = ("...", "gray")
symRepr (SymNumber val) = (show val, "green")
symRepr (SymOperator val) = (text, "yellow")
  where
    text = fromMaybe (':' : show val) $ lookup val ops
    ops = [ (0, "ap")
          , (12, "=")
          -- constants
          , (2, "t")
          , (8, "f")
          -- binary operators
          , (40, "div")
          , (146, "mul")
          , (365, "add")
          , (401, "dec")
          , (417, "inc")
          , (448, "eq")
          ]
symRepr (SymVariable val) = ('x' : show val, "blue")

symRepr' :: Img -> (Coord, Size) -> (Coord, Size, String, String)
symRepr' img (coord, size) =
  (coord, size, text, color)
  where (text, color) = symRepr $ symDecode img coord size

main :: IO ()
main = do
  [fnameIn, fnameSvg, fnameTxt] <- getArgs
  img <- imgLoad fnameIn 4
  writeFile fnameSvg $ annotateImg img
  writeFile fnameTxt $ decodeImg img
