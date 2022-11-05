create_clock -name CLK -period 12MHz [get_ports {CLK}]

derive_pll_clocks -create_base_clocks

derive_clock_uncertainty