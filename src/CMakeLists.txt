# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(smart_pdf_library VERSION 0.0.1 LANGUAGES C)

add_library(smart_pdf SHARED
  "smart_pdf.c"
)

set_target_properties(smart_pdf PROPERTIES
  PUBLIC_HEADER smart_pdf.h
  OUTPUT_NAME "smart_pdf"
)

target_compile_definitions(smart_pdf PUBLIC DART_SHARED_LIB)
