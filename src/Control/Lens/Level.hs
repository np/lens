{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE FlexibleContexts #-}
module Control.Lens.Level
  ( Level
  , levels
  , ilevels
  ) where

import Control.Applicative
import Control.Lens.Internal
import Control.Lens.Traversal
import Control.Lens.Type
import Data.Profunctor
import Data.Profunctor.Rep
import Data.Profunctor.Unsafe
import Data.Foldable
import Data.Monoid
import Data.Word

levelIns :: Bazaar (->) (->) a b t -> [Level () a]
levelIns = go 0 . (runAccessor #. bazaar (Accessor #. deepening ())) where
  go k z = k `seq` runDeepening z k $ \ xs b ->
    xs : if b then (go $! k + 1) z else []
{-# INLINE levelIns #-}

levelOuts :: Bazaar (->) (->) a b t -> [Level j b] -> t
levelOuts bz = runFlows $ runBazaar bz $ \ _ -> Flows $ \t -> case t of
  One _ a : _ -> a
  _            -> error "levelOuts: wrong shape"
{-# INLINE levelOuts #-}

levels :: ATraversal s t a b -> IndexedTraversal Int s t (Level () a) (Level () b)
levels l f s = levelOuts bz <$> traversed f (levelIns bz) where
  bz = l sell s
{-# INLINE levels #-}

ilevelIns :: Bazaar (Indexed i) (->) a b t -> [Level i a]
ilevelIns = go 0 . (runAccessor #. bazaar (Indexed $ \ i -> Accessor #. deepening i)) where
  go k z = k `seq` runDeepening z k $ \ xs b ->
    xs : if b then (go $! k + 1) z else []
{-# INLINE ilevelIns #-}

ilevelOuts :: Bazaar (Indexed i) (->) a b t -> [Level j b] -> t
ilevelOuts bz = runFlows $ runBazaar bz $ Indexed $ \ _ _ -> Flows $ \t -> case t of
  One _ a : _ -> a
  _            -> error "ilevelOuts: wrong shape"
{-# INLINE ilevelOuts #-}

ilevels :: AnIndexedTraversal i s t a b -> IndexedTraversal Int s t (Level i a) (Level j b)
ilevels l f s = ilevelOuts bz <$> traversed f (ilevelIns bz) where
  bz = l sell s
{-# INLINE ilevels #-}