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

#include "tkv.h"
#include "tkvDef.h"

static pthread_once_t isInit = PTHREAD_ONCE_INIT;
static STkvReadOpts   defaultReadOpts;
static STkvWriteOpts  defaultWriteOpts;

static void tkvInit();

STkvDb *tkvOpen(const STkvOpts *options, const char *path) {
  pthread_once(&isInit, tkvInit);
  STkvDb *pDb = NULL;

  pDb = (STkvDb *)malloc(sizeof(*pDb));
  if (pDb == NULL) {
    return NULL;
  }

#ifdef USE_ROCKSDB
  char *err = NULL;

  pDb->db = rocksdb_open(options->opts, path, &err);
  // TODO: check err
#endif

  return pDb;
}

void tkvClose(STkvDb *pDb) {
  if (pDb) {
#ifdef USE_ROCKSDB
    rocksdb_close(pDb->db);
#endif
    free(pDb);
  }
}

void tkvPut(STkvDb *pDb, const STkvWriteOpts *pwopts, const char *key, size_t keylen, const char *val, size_t vallen) {
#ifdef USE_ROCKSDB
  char *err = NULL;
  rocksdb_put(pDb->db, pwopts ? pwopts->wopts : defaultWriteOpts.wopts, key, keylen, val, vallen, &err);
  // TODO: check error
#endif
}

char *tkvGet(STkvDb *pDb, const STkvReadOpts *propts, const char *key, size_t keylen, size_t *vallen) {
  char *ret = NULL;

#ifdef USE_ROCKSDB
  char *err = NULL;
  ret = rocksdb_get(pDb->db, propts ? propts->ropts : defaultReadOpts.ropts, key, keylen, vallen, &err);
  // TODD: check error
#endif

  return ret;
}

STkvOpts *tkvOptsCreate() {
  STkvOpts *pOpts = NULL;

  pOpts = (STkvOpts *)malloc(sizeof(*pOpts));
  if (pOpts == NULL) {
    return NULL;
  }

#ifdef USE_ROCKSDB
  pOpts->opts = rocksdb_options_create();
  // TODO: check error
#endif

  return pOpts;
}

void tkvOptsDestroy(STkvOpts *pOpts) {
  if (pOpts) {
#ifdef USE_ROCKSDB
    rocksdb_options_destroy(pOpts->opts);
#endif
    free(pOpts);
  }
}

void tkvOptionsSetCache(STkvOpts *popts, STkvCache *pCache) {
  // TODO
}

void tkvOptsSetCreateIfMissing(STkvOpts *pOpts, unsigned char c) {
#ifdef USE_ROCKSDB
  rocksdb_options_set_create_if_missing(pOpts->opts, c);
#endif
}

STkvReadOpts *tkvReadOptsCreate() {
  STkvReadOpts *pReadOpts = NULL;

  pReadOpts = (STkvReadOpts *)malloc(sizeof(*pReadOpts));
  if (pReadOpts == NULL) {
    return NULL;
  }

#ifdef USE_ROCKSDB
  pReadOpts->ropts = rocksdb_readoptions_create();
#endif

  return pReadOpts;
}

void tkvReadOptsDestroy(STkvReadOpts *pReadOpts) {
  if (pReadOpts) {
#ifdef USE_ROCKSDB
    rocksdb_readoptions_destroy(pReadOpts->ropts);
#endif
    free(pReadOpts);
  }
}

STkvWriteOpts *tkvWriteOptsCreate() {
  STkvWriteOpts *pWriteOpts = NULL;

  pWriteOpts = (STkvWriteOpts *)malloc(sizeof(*pWriteOpts));
  if (pWriteOpts == NULL) {
    return NULL;
  }

#ifdef USE_ROCKSDB
  pWriteOpts->wopts = rocksdb_writeoptions_create();
#endif

  return pWriteOpts;
}

void tkvWriteOptsDestroy(STkvWriteOpts *pWriteOpts) {
  if (pWriteOpts) {
#ifdef USE_ROCKSDB
    rocksdb_writeoptions_destroy(pWriteOpts->wopts);
#endif
    free(pWriteOpts);
  }
}

/* ------------------------ STATIC METHODS ------------------------ */
static void tkvInit() {
#ifdef USE_ROCKSDB
  defaultReadOpts.ropts = rocksdb_readoptions_create();
  defaultWriteOpts.wopts = rocksdb_writeoptions_create();
  rocksdb_writeoptions_disable_WAL(defaultWriteOpts.wopts, true);
  
#endif
}

static void tkvClear() {
#ifdef USE_ROCKSDB
  rocksdb_readoptions_destroy(defaultReadOpts.ropts);
  rocksdb_writeoptions_destroy(defaultWriteOpts.wopts);
#endif
}
