/*
 * Copyright (c) 2019 TAOS Data, Inc. <jhtao@taosdata.com>
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

#ifndef _TD_TRANSACTION_H_
#define _TD_TRANSACTION_H_

#include "sdb.h"
#include "taosmsg.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
} STrans;

int32_t trnInit();
void    trnCleanup();

STrans *trnCreate();
int32_t trnCommit(STrans *);
void    trnDrop(STrans *);

void trnAppendRedoLog(STrans *, SSdbRawData *);
void trnAppendUndoLog(STrans *, SSdbRawData *);
void trnAppendCommitLog(STrans *, SSdbRawData *);
void trnAppendRedoAction(STrans *, SEpSet *, void *pMsg);
void trnAppendUndoAction(STrans *, SEpSet *, void *pMsg);

#ifdef __cplusplus
}
#endif

#endif /*_TD_TRANSACTION_H_*/
