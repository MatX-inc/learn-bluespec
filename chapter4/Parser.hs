module Parser where

import Data.Char (isDigit)

data ParseResult a
  = NoParse
  | ParseOk { consumed :: a, remaining :: String }
  deriving Show

data Parser a = Parser { runParser :: String -> ParseResult a }

-- ── Typeclass instances ───────────────────────────────────────────────────────

instance Functor Parser where
  fmap f p = Parser $ \input ->
    case runParser p input of
      NoParse                              -> NoParse
      ParseOk { consumed = x, remaining = r } -> ParseOk { consumed = f x, remaining = r }

instance Applicative Parser where
  pure x = Parser $ \input -> ParseOk { consumed = x, remaining = input }
  pf <*> px = Parser $ \input ->
    case runParser pf input of
      NoParse                              -> NoParse
      ParseOk { consumed = f, remaining = r1 } ->
        case runParser px r1 of
          NoParse                              -> NoParse
          ParseOk { consumed = x, remaining = r2 } -> ParseOk { consumed = f x, remaining = r2 }

instance Monad Parser where
  return = pure
  p >>= f = Parser $ \input ->
    case runParser p input of
      NoParse                              -> NoParse
      ParseOk { consumed = x, remaining = r } -> runParser (f x) r

-- ── Choice combinator ─────────────────────────────────────────────────────────

(<|>) :: Parser a -> Parser a -> Parser a
p <|> q = Parser $ \input ->
  case runParser p input of
    NoParse -> runParser q input
    result  -> result

infixl 3 <|>

-- ── Primitive parsers ─────────────────────────────────────────────────────────

-- Consume one character, fail on empty input.
item :: Parser Char
item = Parser $ \input ->
  case input of
    []     -> NoParse
    (c:cs) -> ParseOk { consumed = c, remaining = cs }

-- Consume one character that satisfies a predicate.
satisfy :: (Char -> Bool) -> Parser Char
satisfy p = do
  c <- item
  if p c then return c else Parser $ \_ -> NoParse

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
