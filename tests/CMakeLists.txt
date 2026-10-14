find_package(Qt6 REQUIRED COMPONENTS Test)
qt_add_executable(scancore_tests tst_parsing.cpp)
target_link_libraries(scancore_tests PRIVATE scancore_core scancore_lexbor Qt6::Test)
add_test(NAME parsing COMMAND scancore_tests)
target_compile_definitions(scancore_tests PRIVATE SCANCORE_SOURCE_DIR="${PROJECT_SOURCE_DIR}")

# Live source checks (network); run by hand or from the scheduled workflow.
qt_add_executable(scancore_probe probe.cpp)
target_link_libraries(scancore_probe PRIVATE scancore_core)
target_compile_definitions(scancore_probe PRIVATE SCANCORE_SOURCE_DIR="${PROJECT_SOURCE_DIR}")
qt_add_resources(scancore_probe probe_lncrawl
    PREFIX /
    BASE ${PROJECT_SOURCE_DIR}/resources
    FILES ${PROJECT_SOURCE_DIR}/resources/lncrawl/sources.json ${PROJECT_SOURCE_DIR}/resources/lncrawl/bridge.py)
