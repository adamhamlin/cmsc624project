// Simple-ish extension to log & view all DDL statements
// Issue "select * from query_log()" to view the log

#include "postgres.h"

#include <math.h>
#include <sys/stat.h>
#include <unistd.h>

#include "access/hash.h"
#include "catalog/pg_authid.h"
#include "executor/instrument.h"
#include "funcapi.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "parser/analyze.h"
#include "parser/parsetree.h"
#include "parser/scanner.h"
#include "parser/scansup.h"
#include "pgstat.h"
#include "storage/fd.h"
#include "storage/ipc.h"
#include "storage/spin.h"
#include "tcop/utility.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/memutils.h"

PG_MODULE_MAGIC;

void _PG_init(void);
void _PG_fini(void);

static int nested_level = 0;
static char query[1024];
static void write_file(const char *str);
static char *read_file(FILE *fp);

static ProcessUtility_hook_type prev_utility_hook = NULL;

Datum query_log(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(query_log);

static void log_this_query(PlannedStmt *pstmt,
							const char *queryString,
							ProcessUtilityContext context,
							ParamListInfo params,
							QueryEnvironment *queryEnv,
							DestReceiver *dest,
							char *completionTag);

/////////////////////////////////////////////////////////////////////////////////////////////

void
_PG_init(void)
{
    prev_utility_hook = ProcessUtility_hook;
	ProcessUtility_hook = log_this_query;
}

void
_PG_fini(void)
{
    ProcessUtility_hook = prev_utility_hook;
}

static void
write_file(const char *str)
{
    FILE *fp = fopen("/tmp/log.stat", "a+");
    if (fp == NULL)
        elog(ERROR,"log: unable to open log file");
    fputs(str, fp);
    fputs("\n", fp);
    fclose(fp);
}

static char *
read_file(FILE *fp)
{
    char *rc = NULL;
    rc = fgets(query, 1023, fp);
    return rc ? query : NULL;
}


static void
log_this_query(PlannedStmt *pstmt,
                const char *queryString,
                ProcessUtilityContext context,
                ParamListInfo params,
                QueryEnvironment *queryEnv,
                DestReceiver *dest,
                char *completionTag)
{
	nested_level++;
    PG_TRY();
    {
	    standard_ProcessUtility(pstmt, queryString, context, params, queryEnv, dest, completionTag);
		if(queryString)
             write_file(queryString);
        nested_level--;
	}
	PG_CATCH();
	{
		nested_level--;
		PG_RE_THROW();
	}
	PG_END_TRY();
}

Datum
query_log(PG_FUNCTION_ARGS)
{
	ReturnSetInfo   *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	    tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext   per_query_ctx;
	MemoryContext   oldcontext;
    Datum           values[2];
    bool            nulls[2] = {0};
    char            pid[25];
    char            *query;
    FILE            *fp;

    per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);
        tupstore = tuplestore_begin_heap(true, false, work_mem);

    fp = fopen("/tmp/log.stat", "r");
    if (fp == NULL)
    {
        elog(WARNING,"log: unable to open log file");
        query = "no more queries";
        sprintf(pid, "%s", "invalid pid");
    }
    else
    {
        sprintf(pid, "%d", (int)getpid());
        query = read_file(fp);
    }
    while(query)
    {
        values[0] = CStringGetTextDatum(query);
        values[1] = CStringGetTextDatum(pid);
        /* Build a tuple descriptor for our result type */
	    if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
            elog(ERROR, "return type must be a row type");

	    rsinfo->returnMode = SFRM_Materialize;
	    rsinfo->setResult = tupstore;
	    rsinfo->setDesc = tupdesc;
        tuplestore_putvalues(tupstore, tupdesc, values, nulls);

        if (fp == NULL)
            break;
        query = read_file(fp);
        if (query == NULL)
            break;
    }
    if (fp)
        fclose(fp);
	tuplestore_donestoring(tupstore);
    MemoryContextSwitchTo(oldcontext);
	return (Datum) 0;
}