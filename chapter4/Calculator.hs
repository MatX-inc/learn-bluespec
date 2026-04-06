module Main where

import Parser

-- Grammar:
--   expr   ::= term   (('+' | '-') term)*
--   term   ::= factor (('*' | '/') factor)*
--   factor ::= natural | '(' expr ')'

-- ── Operator parsers ──────────────────────────────────────────────────────────

addOp :: Parser (Int -> Int -> Int)
addOp = (char '+' >> return (+)) <|> (char '-' >> return (-))

mulOp :: Parser (Int -> Int -> Int)
mulOp = (char '*' >> return (*)) <|> (char '/' >> return div)

-- ── Raw style (explicit >>= and >>) ──────────────────────────────────────────

-- Parse zero or more (op, operand) pairs left-associatively.
chainRaw :: Parser (Int -> Int -> Int) -> Parser Int -> Int -> Parser Int
chainRaw op p acc =
  (op >>= \f -> p >>= \x -> chainRaw op p (f acc x))
  <|> return acc

factorRaw :: Parser Int
factorRaw =
  natural <|>
  (char '(' >> exprRaw >>= \e -> char ')' >> return e)

termRaw :: Parser Int
termRaw = factorRaw >>= chainRaw mulOp factorRaw

exprRaw :: Parser Int
exprRaw = termRaw >>= chainRaw addOp termRaw

-- ── Do notation style ─────────────────────────────────────────────────────────

chain :: Parser (Int -> Int -> Int) -> Parser Int -> Int -> Parser Int
chain op p acc =
  (do f <- op
      x <- p
      chain op p (f acc x))
  <|> return acc

factor :: Parser Int
factor = natural <|> do
  _ <- char '('
  e <- expr
  _ <- char ')'
  return e

term :: Parser Int
term = do
  f <- factor
  chain mulOp factor f

expr :: Parser Int
expr = do
  t <- term
  chain addOp term t

-- ── Demo ──────────────────────────────────────────────────────────────────────

eval :: Parser Int -> String -> String
eval p s = case runParser p s of
  Just (n, "") -> show n
  Just (n, r)  -> show n ++ "  (leftover: \"" ++ r ++ "\")"
  Nothing      -> "parse error"

main :: IO ()
main = do
  let tests = ["1+2*3", "10-4/2", "(1+2)*3", "42", "2*(3+4*(5-1))"]
  putStrLn $ pad 20 "Expression" ++ pad 14 "do-style" ++ "raw style"
  putStrLn (replicate 46 '-')
  mapM_ (\s -> putStrLn $ pad 20 s ++ pad 14 (eval expr s) ++ eval exprRaw s) tests
  where
    pad n s = s ++ replicate (n - length s) ' '
