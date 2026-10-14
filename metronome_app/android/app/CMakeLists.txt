cmake_minimum_required(VERSION 3.4.1)

add_library(metronome_engine SHARED ../../windows_linux_cpp/metronome_engine.cpp)

find_library(log-lib log)
target_link_libraries(metronome_engine ${log-lib})
