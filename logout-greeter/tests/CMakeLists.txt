configure_file(config.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.h)

add_executable(logout-greeter-test main.cpp)
target_link_libraries(logout-greeter-test Qt::Core Qt::Concurrent)
ecm_mark_as_test(logout-greeter-test)
