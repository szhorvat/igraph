#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
    #define __BEGIN_DECLS extern "C" {
    #define __END_DECLS }
#else
    #define __BEGIN_DECLS /* empty */
    #define __END_DECLS /* empty */
#endif

/* _WIN32 is always defined on Windows (both 32- and 64-bit systems).
 * It is defined by the compiler itself, thus it does not depend on the inclusion of headers.
 * Reference: https://docs.microsoft.com/en-us/cpp/preprocessor/predefined-macros */
#undef DECLDIR
#if defined (_WIN32)
    #ifdef IGRAPH_EXPORTS
        #define DECLDIR __declspec(dllexport)
    #elif defined(IGRAPH_STATIC)
        #define DECLDIR /**/
    #else
        #define DECLDIR __declspec(dllimport)
    #endif
#else
    #define DECLDIR /**/
#endif

/* This is to eliminate gcc warnings about unused parameters */
#define IGRAPH_UNUSED(x) (void)(x)
