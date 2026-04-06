module Parser where

import Data.Char (isDigit)

newtype Parser a = Parser { runParser :: String -> Maybe (a, String) }

-- ── Typeclass instances ───────────────────────────────────────────────────────

instance Functor Parser where
  fmap f p = Parser $ \input -> do
    (x, rest) <- runParser p input
    return (f x, rest)

instance Applicative Parser where
  pure x = Parser $ \input -> Just (x, input)
  pf <*> px = Parser $ \input -> do
    (f, rest1) <- runParser pf input
    (x, rest2) <- runParser px rest1
    return (f x, rest2)

instance Monad Parser where
  return = pure
  p >>= f = Parser $ \input -> do
    (x, rest) <- runParser p input
    runParser (f x) rest

-- ── Choice combinator ─────────────────────────────────────────────────────────

(<|>) :: Parser a -> Parser a -> Parser a
p <|> q = Parser $ \input ->
  case runParser p input of
    Nothing -> runParser q input
    result  -> result

infixl 3 <|>

-- ── Primitive parsers ─────────────────────────────────────────────────────────

-- Consume one character, fail on empty input.
item :: Parser Char
item = Parser $ \input ->
  case input of
    []     -> Nothing
    (c:cs) -> Just (c, cs)

-- Consume one character that satisfies a predicate.
satisfy :: (Char -> Bool) -> Parser Char
satisfy p = do
  c <- item
  if p c then return c else Parser $ \_ -> Nothing

char :: Char -> Parser Char
char c = satisfy (== c)

digit :: Parser Char
digit = satisfy isDigit

-- ── Repetition combinators ────────────────────────────────────────────────────

-- Zero or more. NOTE: if `p` never fails, `many p` will loop forever.
many :: Parser a -> Parser [a]
many p = some p <|> return []

-- One or more.
some :: Parser a -> Parser [a]
some p = do
  x  <- p
  xs <- many p
  return (x : xs)

-- Parse a multi-digit non-negative integer.
natural :: Parser Int
natural = do
  ds <- some digit
  return (read ds)
