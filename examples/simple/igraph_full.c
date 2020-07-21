/* -*- mode: C -*-  */
/*
   IGraph library.
   Copyright (C) 2006-2012  Gabor Csardi <csardi.gabor@gmail.com>
   334 Harvard st, Cambridge MA, 02139 USA

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

#include <igraph.h>

int main() {

    igraph_t g;
    long int n_vertices = 10;

    /* Create full graph, undirected */
    igraph_full(&g, n_vertices, 0 /*undirected*/, 0/*no loops*/);

    /* Remember to destroy the object at the end */
    igraph_destroy(&g);

    /* Create full graph, directed */
    igraph_full(&g, n_vertices, 1 /*directed*/, 0/*no loops*/);

    igraph_destroy(&g);

    /* Create full graph, undirected with self loops */
    igraph_full(&g, n_vertices, 0 /*undirected*/, 1/*loops*/);

    igraph_destroy(&g);

    /* Create full graph, directed with self loops */
    igraph_full(&g, n_vertices, 1 /*directed*/, 1/*loops*/);

    igraph_destroy(&g);

    return 0;

}
