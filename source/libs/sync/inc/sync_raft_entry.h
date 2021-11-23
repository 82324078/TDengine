/*
 * Copyright (c) 2019 TAOS Data, Inc. <cli@taosdata.com>
 *
 * This program is free software: you can use, redistribute, and/or modify
 * it under the terms of the GNU Affero General Public License, version 3
 * or later ("AGPL"), as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _TD_LIBS_SYNC_RAFT_ENTRY__H
#define _TD_LIBS_SYNC_RAFT_ENTRY__H

#include "sync.h"
#include "sync_type.h"

SSyncRaftEntryArray* syncRaftCreateEntryArray();

SyncIndex syncRaftLastIndexOfEntries(const SSyncRaftEntryArray* ents, int i);

SyncIndex syncRaftIndexOfEntries(const SSyncRaftEntryArray* ents, int i);

#endif // _TD_LIBS_SYNC_RAFT_STABLE_LOG_H
