-- | Interface to Blocks DB.

module Pos.Modern.DB.Block
       ( getBlock
       , getStoredBlock
       , getUndo
       , isBlockInMainChain

       , deleteBlock
       , putBlock
       ) where

import           Data.ByteArray          (convert)
import           Universum

import           Pos.Binary              (Bi)
import           Pos.Modern.DB.Class     (MonadDB, getBlockDB)
import           Pos.Modern.DB.Functions (rocksDelete, rocksGetBi, rocksPutBi)
import           Pos.Modern.DB.Types     (StoredBlock (..))
import           Pos.Ssc.Class           (Ssc)
import           Pos.Types               (Block, HeaderHash, Undo, headerHash)

-- | Get StoredBlock by hash from Block DB.
getStoredBlock
    :: (Ssc ssc, MonadDB ssc m)
    => HeaderHash ssc -> m (Maybe (StoredBlock ssc))
getStoredBlock = getBi . blockKey

-- | Get block with given hash from Block DB.
getBlock
    :: (Ssc ssc, MonadDB ssc m)
    => HeaderHash ssc -> m (Maybe (Block ssc))
getBlock = fmap (fmap sbBlock) . getStoredBlock

-- | Get block with given hash from Block DB.
isBlockInMainChain
    :: (Ssc ssc, MonadDB ssc m)
    => HeaderHash ssc -> m Bool
isBlockInMainChain = fmap (maybe True sbInMain) . getStoredBlock

-- | Get undo data for block with given hash from Block DB.
getUndo
    :: (MonadDB ssc m)
    => HeaderHash ssc -> m (Maybe Undo)
getUndo = getBi . undoKey

-- | Put given block and its metadata into Block DB.
putBlock
    :: (Ssc ssc, MonadDB ssc m)
    => Bool -> Block ssc -> m ()
putBlock inMainChain blk =
    putBi
        (blockKey $ headerHash blk)
        StoredBlock
        { sbBlock = blk
        , sbInMain = inMainChain
        }

deleteBlock :: (MonadDB ssc m) => HeaderHash ssc -> m ()
deleteBlock = delete . blockKey

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

getBi
    :: (MonadDB ssc m, Bi v)
    => ByteString -> m (Maybe v)
getBi k = rocksGetBi k =<< getBlockDB

putBi
    :: (MonadDB ssc m, Bi v)
    => ByteString -> v -> m ()
putBi k v = rocksPutBi k v =<< getBlockDB

delete :: (MonadDB ssc m) => ByteString -> m ()
delete k = rocksDelete k =<< getBlockDB

blockKey :: HeaderHash ssc -> ByteString
blockKey h = "b" <> convert h

undoKey :: HeaderHash ssc -> ByteString
undoKey h = "u" <> convert h
