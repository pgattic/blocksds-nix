cmake_minimum_required(VERSION 3.16)

project(cmake_example LANGUAGES C)

add_library(portable-core
  src/game_logic.c
)
target_include_directories(portable-core PUBLIC src/core)

if(NINTENDO_DS) # NINTENDO_DS variable is set by BlocksDS cmake file
  if(NDS_DSI_EXCLUSIVE)
    set(SUBTITLE "DSi Edition")
  else()
    set(SUBTITLE "DS Edition")
  endif()
  add_executable(portable-demo
    src/nds/main_nds.c
  )
  target_link_libraries(portable-demo PRIVATE portable-core)

  # BlocksDS helper: produce .nds file
  nds_create_rom(portable-demo
    NAME "Example Game"
    SUBTITLE "${SUBTITLE}"
    AUTHOR "pgattic"
  )
else()
  add_executable(portable-demo
    src/linux/main_linux.c
  )
  target_link_libraries(portable-demo PRIVATE portable-core)
endif()

