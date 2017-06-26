CREATE OR REPLACE PACKAGE om_tapigen
   AUTHID CURRENT_USER
IS
   /*
   THIS IS A TABLE API GENERATOR
   Source and documentation: github.com/OraMUC/table-api-generator

   The MIT License (MIT)

   Copyright (c) 2015-2017 André Borngräber, Ottmar Gobrecht

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
   */

   -----------------------------------------------------------------------------
   -- public global constants c_*
   -----------------------------------------------------------------------------
   c_generator                     CONSTANT VARCHAR2 (10 CHAR) := 'OM_TAPIGEN';
   c_generator_version             CONSTANT VARCHAR2 (10 CHAR) := '0.5.0';

   -- parameter defaults
   c_reuse_existing_api_params     CONSTANT BOOLEAN := TRUE; -- if true, all other parameters are ignored
   c_enable_insertion_of_rows      CONSTANT BOOLEAN := TRUE;
   c_enable_update_of_rows         CONSTANT BOOLEAN := TRUE;
   c_enable_deletion_of_rows       CONSTANT BOOLEAN := FALSE;
   c_enable_parameter_prefixes     CONSTANT BOOLEAN := TRUE;
   c_enable_proc_with_out_params   CONSTANT BOOLEAN := TRUE;
   c_enable_getter_and_setter      CONSTANT BOOLEAN := TRUE;
   c_col_prefix_in_method_names    CONSTANT BOOLEAN := TRUE; -- only relevant, when p_enable_getter_and_setter is true
   c_return_row_instead_of_pk      CONSTANT BOOLEAN := FALSE;
   c_enable_dml_view               CONSTANT BOOLEAN := FALSE;
   c_enable_generic_change_log     CONSTANT BOOLEAN := FALSE;
   c_api_name                      CONSTANT VARCHAR2 (1) := NULL;
   c_sequence_name                 CONSTANT VARCHAR2 (1) := NULL;
   c_column_defaults               CONSTANT XMLTYPE := NULL;


   -----------------------------------------------------------------------------
   -- public row and table types for pipelined functions
   -----------------------------------------------------------------------------
   TYPE g_row_existing_apis IS RECORD
   (
      errors                          VARCHAR2 (4000 CHAR),
      owner                           all_users.username%TYPE,
      table_name                      all_objects.object_name%TYPE,
      package_name                    all_objects.object_name%TYPE,
      spec_status                     all_objects.status%TYPE,
      spec_last_ddl_time              all_objects.last_ddl_time%TYPE,
      body_status                     all_objects.status%TYPE,
      body_last_ddl_time              all_objects.last_ddl_time%TYPE,
      generator                       VARCHAR2 (10 CHAR),
      generator_version               VARCHAR2 (10 CHAR),
      generator_action                VARCHAR2 (24 CHAR),
      generated_at                    DATE,
      generated_by                    all_users.username%TYPE,
      p_owner                         all_users.username%TYPE,
      p_table_name                    all_objects.object_name%TYPE,
      p_reuse_existing_api_params     VARCHAR2 (5 CHAR),
      p_enable_insertion_of_rows      VARCHAR2 (5 CHAR),
      p_enable_update_of_rows         VARCHAR2 (5 CHAR),
      p_enable_deletion_of_rows       VARCHAR2 (5 CHAR),
      p_enable_parameter_prefixes     VARCHAR2 (5 CHAR),
      p_enable_proc_with_out_params   VARCHAR2 (5 CHAR),
      p_enable_getter_and_setter      VARCHAR2 (5 CHAR),
      p_col_prefix_in_method_names    VARCHAR2 (5 CHAR),
      p_return_row_instead_of_pk      VARCHAR2 (5 CHAR),
      p_enable_dml_view               VARCHAR2 (5 CHAR),
      p_enable_generic_change_log     VARCHAR2 (5 CHAR),
      p_api_name                      all_objects.object_name%TYPE,
      p_sequence_name                 all_objects.object_name%TYPE,
      p_column_defaults               VARCHAR2 (30 CHAR)
   );

   TYPE g_tab_existing_apis IS TABLE OF g_row_existing_apis;

   --

   TYPE g_row_naming_conflicts IS RECORD
   (
      object_name     ALL_OBJECTS.OBJECT_NAME%TYPE,
      object_type     ALL_OBJECTS.OBJECT_TYPE%TYPE,
      status          ALL_OBJECTS.STATUS%TYPE,
      last_ddl_time   ALL_OBJECTS.LAST_DDL_TIME%TYPE
   );

   TYPE g_tab_naming_conflicts IS TABLE OF g_row_naming_conflicts;

   --------------------------------------------------------------------------------
   PROCEDURE compile_api (
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE DEFAULT USER,
      p_reuse_existing_api_params     IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
      --^ if true, the following params are ignored when API package are already existing and params are extractable from spec source
      p_enable_insertion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows         IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_parameter_prefixes     IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_enable_proc_with_out_params   IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
      p_enable_getter_and_setter      IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_col_prefix_in_method_names    IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_return_row_instead_of_pk      IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_enable_dml_view               IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_enable_generic_change_log     IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_api_name                      IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_sequence_name                 IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_column_defaults               IN XMLTYPE DEFAULT om_tapigen.c_column_defaults);

   --------------------------------------------------------------------------------
   FUNCTION compile_api_and_get_code (
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE DEFAULT USER,
      p_reuse_existing_api_params     IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
      --^ if true, the following params are ignored when API package are already existing and params are extractable from spec source
      p_enable_insertion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows         IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_parameter_prefixes     IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_enable_proc_with_out_params   IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
      p_enable_getter_and_setter      IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_col_prefix_in_method_names    IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_return_row_instead_of_pk      IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_enable_dml_view               IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_enable_generic_change_log     IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_api_name                      IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_sequence_name                 IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_column_defaults               IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
      RETURN CLOB;

   --------------------------------------------------------------------------------
   FUNCTION get_code (
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE DEFAULT USER,
      p_reuse_existing_api_params     IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
      --^ if true, the following params are ignored when API package are already existing and params are extractable from spec source
      p_enable_insertion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows         IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_parameter_prefixes     IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_enable_proc_with_out_params   IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
      p_enable_getter_and_setter      IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_col_prefix_in_method_names    IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_return_row_instead_of_pk      IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_enable_dml_view               IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_enable_generic_change_log     IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_api_name                      IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_sequence_name                 IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_column_defaults               IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
      RETURN CLOB;

   --------------------------------------------------------------------------------
   -- A one liner to recreate all APIs in the current (or another) schema with 
   -- the original call parameters (read from the package specs):
   -- EXEC om_tapigen.recreate_existing_apis;
   PROCEDURE recreate_existing_apis (
      p_owner   IN all_users.username%TYPE DEFAULT USER);

   --------------------------------------------------------------------------------
   -- A helper function to list all APIs generated by om_tapigen:
   -- SELECT * FROM TABLE (om_tapigen.view_existing_apis);
   FUNCTION view_existing_apis (
      p_table_name    all_tables.table_name%TYPE DEFAULT NULL,
      p_owner         all_users.username%TYPE DEFAULT USER)
      RETURN g_tab_existing_apis
      PIPELINED;

   --------------------------------------------------------------------------------
   -- A helper to ckeck possible naming conflicts before the first usage of the API generator:
   -- SELECT * FROM TABLE (om_tapigen.view_naming_conflicts);
   -- No rows expected. After you generated some APIs there will be results ;-)
   FUNCTION view_naming_conflicts (
      p_owner    all_users.username%TYPE DEFAULT USER)
      RETURN g_tab_naming_conflicts
      PIPELINED;

   --------------------------------------------------------------------------------
   -- Working with long columns: http://www.oracle-developer.net/display.php?id=430
   -- The following helper function is needed to read a column data default from the dictionary:
   FUNCTION util_get_column_data_default (
      p_table_name    IN VARCHAR2,
      p_column_name   IN VARCHAR2,
      p_owner            VARCHAR2 DEFAULT USER)
      RETURN VARCHAR2;

   --------------------------------------------------------------------------------
   -- Working with long columns: http://www.oracle-developer.net/display.php?id=430
   -- The following helper function is needed to read a constraint search condition from the dictionary:
   -- (not needed in 12cR1 and above, there we have a column search_condition_vc in user_constraints)
   FUNCTION util_get_cons_search_condition (
      p_constraint_name   IN VARCHAR2,
      p_owner             IN VARCHAR2 DEFAULT USER)
      RETURN VARCHAR2;

   --------------------------------------------------------------------------------
   -- A helper function for util_get_custom_col_defaults which reads a random row
   -- from a table and converts (transpose) the data so that it is joinable to
   -- user_tab_columns whith the help of the xmltable function. See also the
   -- source of util_get_custom_col_defaults for a usage example.
   -- SELECT XMLSERIALIZE (DOCUMENT om_tapigen.util_table_row_to_xml ('EMPLOYEES') INDENT) FROM DUAL;
   -- SELECT x.column_name,
   --        x.data_random_row
   --   FROM XMLTABLE ('/rowset/row' PASSING om_tapigen.util_table_row_to_xml ('EMPLOYEES') COLUMNS
   --           column_name     VARCHAR2  (128) PATH './col',
   --           data_random_row VARCHAR2 (4000) PATH './val') x;
   FUNCTION util_table_row_to_xml (p_table_name    VARCHAR2,
                                   p_owner         VARCHAR2 DEFAULT USER)
      RETURN XMLTYPE;

   --------------------------------------------------------------------------------
   -- A standalone function to get hopefully useful custom column defaults. This
   -- is always work in progress, because it is impossible to create logic,
   -- that meets the requirements of all possible use cases. You can grab this
   -- code as base for your own implementation ;-)
   -- If you want to check the output in a readable format then try this:
   -- SELECT XMLSERIALIZE (DOCUMENT om_tapigen.util_get_custom_col_defaults ('EMPLOYEES') INDENT) FROM DUAL;
   -- Yes, it is slow because of heavy use of the dictionary. If you have a better idea, please let us know...
   FUNCTION util_get_custom_col_defaults (
      p_table_name    VARCHAR2,
      p_owner         VARCHAR2 DEFAULT USER)
      RETURN XMLTYPE;
--------------------------------------------------------------------------------
END om_tapigen;
/