%let pgm=utl-import-a-sqlite-table-with-data-types-without-sas-access-product;

%stop_submission;

import a sqlite table with data types without sas access product

SOAPBOX ON
   This is an open source solution.

   I had issues shelling out to the dos cmd.exe, so I used my drop down to powershell.
   2 I used R to create and load the students table
   3 used do_over to handle the meta daa. This is a goog use of macro arrays.
   4 I used my utl_optlenpos macro to shink char and mumeric to minimum lengths witout loss of precision.

   I would not be surprised if this work with other databases?

SOAPBOX OFF

github
https://tinyurl.com/42zyttre
https://github.com/rogerjdeangelis/utl-import-a-sqlite-table-with-data-types-without-sas-access-product

/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.students;
   informat name $8. sex $2. ;
   input name sex age height weight;
cards4;
Alfred  M 14 69.0 112.5
Alice   F 13 56.5 84.0
Barbara F 13 65.3 98.0
Carol   F 14 62.8 102.5
Henry   M 14 63.5 102.5
;;;;
run;quit;

* Using R to create sqlite table;

%utlfkil(d:/sqlite/have.db);

%utl_rbeginx;
parmcards4;
library(haven)
library(DBI)
library(RSQLite)
students<-read_sas(
 "d:/sd1/students.sas7bdat")
con <- dbConnect(
    RSQLite::SQLite()
   ,"d:/sqlite/have.db")
dbWriteTable(
    con
  ,"students"
  ,students)
dbListTables(con)
dbGetQuery(
   con
 ,"select
     *
   from
     students")
dbGetQuery(
   con
 ,"select
     *
  from
   pragma_table_info('students')")
dbDisconnect(con)
;;;;
%utl_rendx;


/**************************************************************************************************************************/
/* SD1.STUDENTS                                                                                                           */
/*                                                                                                                        */
/*  NAME   SEX AGE HEIGHT WEIGHT                                                                                          */
/*                                                                                                                        */
/* Alfred   M   14  69.0   112.5                                                                                          */
/* Alice    F   13  56.5    84.0                                                                                          */
/* Barbara  F   13  65.3    98.0                                                                                          */
/* Carol    F   14  62.8   102.5                                                                                          */
/* Henry    M   14  63.5   102.5                                                                                          */
/*                                                                                                                        */
/* SQLITE TABLE                                                                                                           */
/*                                                                                                                        */
/* META DATA ON STUDENTS                                                                                                  */
/*                     not                                                                                                */
/*   cid   name type  null dflt  pk                                                                                       */
/* 1   0   NAME TEXT     0 NA     0                                                                                       */
/* 2   1    SEX TEXT     0 NA     0                                                                                       */
/* 3   2    AGE REAL     0 NA     0                                                                                       */
/* 4   3 HEIGHT REAL     0 NA     0                                                                                       */
/* 5   4 WEIGHT REAL     0 NA     0                                                                                       */
/**************************************************************************************************************************/

/*
 _ __  _ __ ___   ___ ___  ___ ___
| `_ \| `__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|
*/

/*---- create csv files from sqlite tables ----*/

%utlfkil(d:/csv/data.csv);
%utlfkil(d:/csv/meta.csv);

proc datasets lib=work nolist nodetails;
   delete meta delete mapem want;
run;quit; \

%arraydelete(_typ);
%arraydelete(_nam);

/*--- I am using powershell ----*/
%utl_psbegin;
parmcards4;
sqlite3 -csv "d:/sqlite/have.db"  "select * from students;" > "d:/csv/data.csv"
sqlite3 -header -csv "d:/sqlite/have.db"  "PRAGMA table_info(students);" > "d:/csv/meta.csv"
;;;;
%utl_psend;

/**************************************************************************************************************************/
/* CSV TABLES                                                                                                             */
/*                                                                                                                        */
/* d:/csv/meta.csv                                                                                                        */
/*                                                                                                                        */
/* id,name,type,notnull,dflt_value,pk                                                                                     */
/*                                                                                                                        */
/* 0,NAME,TEXT,0,,0                                                                                                       */
/* 1,SEX,TEXT,0,,0                                                                                                        */
/* 2,AGE,REAL,0,,0                                                                                                        */
/* 3,HEIGHT,REAL,0,,0                                                                                                     */
/* 4,WEIGHT,REAL,0,,0                                                                                                     */
/*                                                                                                                        */
/* d:/csv/data.csv                                                                                                        */
/*                                                                                                                        */
/* Alfred,M,14.0,69.0,112.5                                                                                               */
/* Alice,F,13.0,56.5,84.0                                                                                                 */
/* Barbara,F,13.0,65.3,98.0                                                                                               */
/* Carol,F,14.0,62.8,102.5                                                                                                */
/* Henry,M,14.0,63.5,102.5                                                                                                */
/**************************************************************************************************************************/

/*---- import meta data names and types ----*/

proc import out=meta
    datafile="d:/csv/meta.csv"
    dbms=csv
    replace;
    getnames=YES;
    guessingrows=MAX;
run;quit;

/**************************************************************************************************************************/
/* ORK.META total obs=5                                                                                                   */
/*                     NOT   DFLT_                                                                                        */
/* CID  NAME     TYPE  NULL VALUE  PK                                                                                     */
/*                                                                                                                        */
/*  0   NAME     TEXT  0            0                                                                                     */
/*  1   SEX      TEXT  0            0                                                                                     */
/*  2   AGE      REAL  0            0                                                                                     */
/*  3   HEIGHT   REAL  0            0                                                                                     */
/*  4   WEIGHT   REAL  0            0                                                                                     */
/**************************************************************************************************************************/

/*---- sqliye types to sas types ----*/

proc format;

 value $maptyp
  'REAL'    = '32.'
  'INTEGER' = '32.'
  'TEXT'    = '$255.';

run;quit;

data mapem;
  set meta(keep=name type);
  typ=put(type,$maptyp.);
  drop type;
run;quit;

/**************************************************************************************************************************/
/*  WORK.MAPEM                                                                                                            */
/*                                                                                                                        */
/*    NAME       TYP                                                                                                      */
/*                                                                                                                        */
/*    NAME      $255.                                                                                                     */
/*    SEX       $255.                                                                                                     */
/*    AGE       32.                                                                                                       */
/*    HEIGHT    32.                                                                                                       */
/*    WEIGHT    32.                                                                                                       */
/**************************************************************************************************************************/

/*---- create macro arrays of meta data - good use of arrays ----*/

%array(_typ,data=mapem,var=typ);
%array(_nam,data=mapem,var=name);

%utlnopts;
%put &=_typn; * _typn = 5     ;

%put &=_typ1; * _typ1 = $255. ;
%put &=_typ2; * _typ2 = $255. ;
%put &=_typ3; * _typ3 = 32.   ;
%put &=_typ4; * _typ4 = 32.   ;
%put &=_typ5; * _typ5 = 32.   ;

%put &=_namn; * _namn = 5     ;

%put &=_nam1; * _nam1 = name  ;
%put &=_nam2; * _nam2 = sex   ;
%put &=_nam3; * _nam3 = age   ;
%put &=_nam4; * _nam4 = height;
%put &=_nam5; * _nam5 = weight;

%utlopts;

/*---- create sas datasets ----*/

data want;
  informat
    %do_over(_nam _typ,phrase=?_nam ?_typ);;
  infile "d:/csv/data.csv" delimiter=',';
  input
    %do_over(_nam,phrase=?);;
run;quit;

/**************************************************************************************************************************/
/*   Variables in Creation Order                                                                                          */
/*                                                                                                                        */
/* Variable    Type    Len    Informat                                                                                    */
/*                                                                                                                        */
/* NAME        Char    255    $255.                                                                                       */
/* SEX         Char    255    $255.                                                                                       */
/* AGE         Num       8    32.                                                                                         */
/* HEIGHT      Num       8    32.                                                                                         */
/* WEIGHT      Num       8    32.                                                                                         */
/*                                                                                                                        */
/*  NAME      SEX    AGE    HEIGHT    WEIGHT                                                                              */
/*                                                                                                                        */
/* Alfred      M      14     69.0      112.5                                                                              */
/* Alice       F      13     56.5       84.0                                                                              */
/* Barbara     F      13     65.3       98.0                                                                              */
/* Carol       F      14     62.8      102.5                                                                              */
/* Henry       M      14     63.5      102.5                                                                              */
/**************************************************************************************************************************/

/*---- optimize variable lengths ----*/

/*--- use max values for char and num lenths)
%utl_optlenpos(want,want);


/**************************************************************************************************************************/
/* Variable    Type    Len                                                                                                */
/*                                                                                                                        */
/* NAME        Char      7                                                                                                */
/* SEX         Char      1                                                                                                */
/* AGE         Num       3                                                                                                */
/* HEIGHT      Num       8                                                                                                */
/* WEIGHT      Num       3  Interesting because of x.5                                                                    */
/*                                                                                                                        */
/*  NAME      SEX    AGE    HEIGHT    WEIGHT                                                                              */
/*                                                                                                                        */
/* Alfred      M      14     69.0      112.5                                                                              */
/* Alice       F      13     56.5       84.0                                                                              */
/* Barbara     F      13     65.3       98.0                                                                              */
/* Carol       F      14     62.8      102.5                                                                              */
/* Henry       M      14     63.5      102.5                                                                              */
/**************************************************************************************************************************/

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/
