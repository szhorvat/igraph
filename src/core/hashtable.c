/* -*- mode: C -*-  */
/*
   IGraph library.
   Copyright (C) 2006-2012  Gabor Csardi <csardi.gabor@gmail.com>
   334 Harvard street, Cambridge, MA 02139 USA

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc.,  51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301 USA

*/

#include "igraph_types.h"
#include "igraph_memory.h"
#include "igraph_error.h"

#include "core/hashtable.h"

#include <string.h>

igraph_error_t igraph_hashtable_init(igraph_hashtable_t *ht) {
    IGRAPH_CHECK(igraph_trie_init(&ht->keys, 1));
    IGRAPH_FINALLY(igraph_trie_destroy, &ht->keys);
    IGRAPH_CHECK(igraph_strvector_init(&ht->elements, 0));
    IGRAPH_FINALLY(igraph_strvector_destroy, &ht->elements);
    IGRAPH_CHECK(igraph_strvector_init(&ht->defaults, 0));

    IGRAPH_FINALLY_CLEAN(2);
    return IGRAPH_SUCCESS;
}

void igraph_hashtable_destroy(igraph_hashtable_t *ht) {
    igraph_trie_destroy(&ht->keys);
    igraph_strvector_destroy(&ht->elements);
    igraph_strvector_destroy(&ht->defaults);
}

/* Note: may leave the hash table in an inconsistent state if a new
   element is added, but this is not a big problem, since while the
   defaults, or the defaults plus the elements may contain more elements
   than the keys trie, but the data is always retrieved based on the trie
*/

igraph_error_t igraph_hashtable_addset(igraph_hashtable_t *ht,
                            const char *key, const char *def,
                            const char *elem) {
    igraph_integer_t size = igraph_trie_size(&ht->keys);
    igraph_integer_t newid;

    IGRAPH_CHECK(igraph_trie_get(&ht->keys, key, &newid));

    if (newid == size) {
        /* this is a new element */
        IGRAPH_CHECK(igraph_strvector_resize(&ht->defaults, newid + 1));
        IGRAPH_CHECK(igraph_strvector_resize(&ht->elements, newid + 1));
        IGRAPH_CHECK(igraph_strvector_set(&ht->defaults, newid, def));
        IGRAPH_CHECK(igraph_strvector_set(&ht->elements, newid, elem));
    } else {
        /* set an already existing element */
        IGRAPH_CHECK(igraph_strvector_set(&ht->elements, newid, elem));
    }

    return IGRAPH_SUCCESS;
}

/* Previous comment also applies here */

igraph_error_t igraph_hashtable_addset_len(igraph_hashtable_t *ht,
                             const char *key, const char *def,
                             const char *elem, size_t elemlen) {
    igraph_integer_t size = igraph_trie_size(&ht->keys);
    igraph_integer_t newid;

    IGRAPH_CHECK(igraph_trie_get(&ht->keys, key, &newid));

    if (newid == size) {
        /* this is a new element */
        IGRAPH_CHECK(igraph_strvector_resize(&ht->defaults, newid + 1));
        IGRAPH_CHECK(igraph_strvector_resize(&ht->elements, newid + 1));
        IGRAPH_CHECK(igraph_strvector_set(&ht->defaults, newid, def));
        IGRAPH_CHECK(igraph_strvector_set_len(&ht->elements, newid, elem, elemlen));
    } else {
        /* set an already existing element */
        IGRAPH_CHECK(igraph_strvector_set_len(&ht->elements, newid, elem, elemlen));
    }

    return IGRAPH_SUCCESS;
}

igraph_error_t igraph_hashtable_get(igraph_hashtable_t *ht,
                         const char *key, const char **elem) {
    igraph_integer_t newid;
    IGRAPH_CHECK(igraph_trie_get(&ht->keys, key, &newid));
    *elem = igraph_strvector_get(&ht->elements, newid);
    return IGRAPH_SUCCESS;
}

igraph_error_t igraph_hashtable_reset(igraph_hashtable_t *ht) {
    igraph_strvector_destroy(&ht->elements);
    IGRAPH_CHECK(igraph_strvector_init_copy(&ht->elements, &ht->defaults));
    return IGRAPH_SUCCESS;
}

igraph_error_t igraph_hashtable_getkeys(igraph_hashtable_t *ht,
                                        const igraph_strvector_t **sv) {
    return igraph_trie_getkeys(&ht->keys, sv);
}
