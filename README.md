Pour compiler:
zig build


//26/12
=> démarrage du soft ok
=> crash de freertos lors du check de VTOR
=> TODO faire du code pour check VTOR avec start scheduler freertos

TODO
-> Ajouter une dépendance à stm32_utils via fichier zon


cf https://github.com/STMicroelectronics/STM32CubeWB/blob/master/Projects/P-NUCLEO-WB55.Nucleo/Applications/BLE/BLE_Peripheral_Lite_EventCallbacks
pour exemple minimaliste

// Tester sortie RTT.zig
// Ajouter writer (rtt ou uart) à logging_defmt init

// Tester sortie defmt avec zrttviewer avec code en dur pour le moment ( pas de lecture enum etc...)

// Tester la partie noinit

// test à la compil du bon nombre d'argument avec log defmt

// driver gpio

// driver ble

// freertos cf github efr32

// driver uart

// protoc

// 

// Générer .map pour analyse à partir de elf
