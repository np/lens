{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Lens.Indexed
-- Copyright   :  (C) 2012 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  rank 2 types, MPTCs, TFs, flexible
--
-- Combinators for working with 'Indexed' functions.
----------------------------------------------------------------------------
module Control.Lens.Indexed
  ( Indexable(..)
  -- * Indexed Functions
  , Indexed(..)
  , (<.>), (<.), (.>)
  , icompose
  , reindexed
  -- * Indexing existing lenses, traversals, etc.
  , indexing
  , indexing64
  -- * withIndex
  , (@~)
  , withIndex
  , IndexedLensLike
  , IndexedLensLike'
  ) where

import Control.Lens.Classes
import Control.Lens.Internal
import Data.Int

infixr 9 <.>, <., .>
infixr 4 @~

withIndex :: (Indexed i s t -> r) -> (i -> s -> t) -> r
withIndex l = l . Indexed
{-# INLINE withIndex #-}


(@~) :: (Indexed i s t -> r) -> (i -> s -> t) -> r
(@~) = withIndex
{-# INLINE (@~) #-}

-- | Compose an 'Indexed' function with a non-indexed function.
--
-- Mnemonically, the @<@ points to the indexing we want to preserve.
(<.) :: Indexable i p => (Indexed i s t -> r) -> ((a -> b) -> s -> t) -> p a b -> r
(<.) f g h = f @~ g . indexed h
{-# INLINE (<.) #-}

-- | Compose a non-indexed function with an 'Indexed' function.
--
-- Mnemonically, the @>@ points to the indexing we want to preserve.
--
-- This is the same as @(.)@: @f.g@ gives you @g@'s index.
(.>) :: (st -> r) -> (kab -> st) -> kab -> r
(.>) = (.)
{-# INLINE (.>) #-}

-- (.>)  :: Indexable i p => (b -> c) -> Indexed i a b -> p a c
-- bc .> Indexed iab = indexed (bc . iab)

-- | Remap the index.
reindexed :: Indexable j p => (i -> j) -> (Indexed i a b -> r) -> p a b -> r
reindexed ij f g = f @~ indexed g . ij
{-# INLINE reindexed #-}

-- | Composition of 'Indexed' functions
--
-- Mnemonically, the @\<@ and @\>@ points to the fact that we want to preserve the indices.
(<.>) :: Indexable (i, j) p => (Indexed i s t -> r) -> (Indexed j a b -> s -> t) -> p a b -> r
f <.> g = icompose (,) f g
{-# INLINE (<.>) #-}

-- | Composition of 'Indexed' functions with a user supplied function for combining indices
icompose :: Indexable p c => (i -> j -> p) -> (Indexed i s t -> r) -> (Indexed j a b -> s -> t) -> c a b -> r
icompose ijk istr jabst cab = istr @~ \i -> jabst @~ \j -> indexed cab $ ijk i j
{-# INLINE icompose #-}

-- | Transform a 'Traversal' into an 'Control.Lens.IndexedTraversal.IndexedTraversal' or
-- a 'Fold' into an 'Control.Lens.IndexedFold.IndexedFold', etc.
--
-- @
-- 'indexing' :: 'Control.Lens.Traversal.Traversal' s t a b -> 'Control.Lens.IndexedTraversal.IndexedTraversal' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Prism.Prism' s t a b         -> 'Control.Lens.IndexedLens.IndexedTraversal' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Type.Lens' s t a b           -> 'Control.Lens.IndexedLens.IndexedLens' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Iso.Iso' s t a b             -> 'Control.Lens.IndexedLens.IndexedLens' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Fold.Fold' s t               -> 'Control.Lens.IndexedFold.IndexedFold' 'Int' s t
-- 'indexing' :: 'Control.Lens.Getter.Getter' s t           -> 'Control.Lens.IndexedGetter.IndexedGetter' 'Int' s t a b
-- @
indexing :: Indexable Int p => ((a -> Indexing f b) -> s -> Indexing f t) -> p a (f b) -> s -> f t
indexing l iafb s = case runIndexing (l (\a -> Indexing (\i -> i `seq` (indexed iafb i a, i + 1))) s) 0 of
  (r, _) -> r
{-# INLINE indexing #-}

-- | Transform a 'Traversal' into an 'Control.Lens.IndexedTraversal.IndexedTraversal' or
-- a 'Fold' into an 'Control.Lens.IndexedFold.IndexedFold', etc.
--
-- This combinator is like 'indexing' except that it handles large 'Traversal's and 'Fold's gracefully.
--
-- @
-- 'indexing64' :: 'Control.Lens.Traversal.Traversal' s t a b -> 'Control.Lens.IndexedTraversal.IndexedTraversal' 'Int64' s t a b
-- 'indexing64' :: 'Control.Lens.Prism.Prism' s t a b         -> 'Control.Lens.IndexedLens.IndexedTraversal' 'Int64' s t a b
-- 'indexing64' :: 'Control.Lens.Type.Lens' s t a b           -> 'Control.Lens.IndexedLens.IndexedLens' 'Int64' s t a b
-- 'indexing64' :: 'Control.Lens.Iso.Iso' s t a b             -> 'Control.Lens.IndexedLens.IndexedLens' 'Int64' s t a b
-- 'indexing64' :: 'Control.Lens.Fold.Fold' s t               -> 'Control.Lens.IndexedFold.IndexedFold' 'Int64' s t
-- 'indexing64' :: 'Control.Lens.Getter.Getter' s t           -> 'Control.Lens.IndexedGetter.IndexedGetter' 'Int64' s t a b
-- @
indexing64 :: Indexable Int64 p => ((a -> Indexing64 f b) -> s -> Indexing64 f t) -> p a (f b) -> s -> f t
indexing64 l iafb s = case runIndexing64 (l (\a -> Indexing64 (\i -> i `seq` (indexed iafb i a, i + 1))) s) 0 of
  (r, _) -> r
{-# INLINE indexing64 #-}

-- | Convenient alias for constructing indexed lenses and their ilk
type IndexedLensLike p f s t a b = p a (f b) -> s -> f t

-- | Convenient alias for constructing simple indexed lenses and their ilk
type IndexedLensLike' p f s a    = p a (f a) -> s -> f s
