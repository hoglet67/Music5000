library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity Music5000_gop is
    port (
        -- System oscillator
        clk49152   : in     std_logic;
        -- BBC 1MHZ Bus
        clke       : in     std_logic;
        rnw        : in     std_logic;
        rst_n      : in     std_logic;
        pgfc_n     : in     std_logic;
        pgfd_n     : in     std_logic;
        bus_addr   : in     std_logic_vector (7 downto 0);
        bus_data   : inout  std_logic_vector (7 downto 0);
        -- SPI DAC
        dac_cs_n   : out    std_logic;
        dac_sck    : out    std_logic;
        dac_sdi    : out    std_logic;
        dac_ldac_n : out    std_logic;
        -- Misc
        sw1        : in     std_logic;
        sw2        : in     std_logic;
        led        : out    std_logic_vector (7 downto 0);
        test       : out    std_logic
    );
end music5000_gop;

architecture Behavioral of Music5000_gop is

signal clk6 : std_logic;
signal clk23783 : std_logic;
signal clkctr : std_logic_vector (1 downto 0);

begin

    ------------------------------------------------
    -- 6MHZ Clock Generation
    -- (from the 49.152MHZ Oscillator)
    -- (the nerest we can get is 5.946MHz)
    ------------------------------------------------

    inst_DCM : DCM
        generic map (
            CLKFX_MULTIPLY   => 15,
            CLKFX_DIVIDE     => 31,
            CLKIN_PERIOD     => 20.345,
            CLK_FEEDBACK     => "NONE"
            )
        port map (
            CLKIN            => clk49152,
            CLKFB            => '0',
            RST              => '0',
            DSSEN            => '0',
            PSINCDEC         => '0',
            PSEN             => '0',
            PSCLK            => '0',
            CLKFX            => clk23783
            );

    clock_divider : process(clk23783, rst_n)
    begin
        if rising_edge(clk23783) then
            clkctr <= std_logic_vector(unsigned(clkctr) + 1);
        end if;
    end process;

    clk6 <= clkctr(1);

    ------------------------------------------------
    -- Music 5000 Core with SPI DAC Interface
    ------------------------------------------------

    inst_Music5000SpiDac : entity work.Music5000SpiDac
        port map (
            -- This is the 6MHz audio clock
            clk6       => clk6       ,
            -- This is the cpu clock
            clke       => clke       ,
            rnw        => rnw        ,
            rst_n      => rst_n      ,
            pgfc_n     => pgfc_n     ,
            pgfd_n     => pgfd_n     ,
            bus_addr   => bus_addr   ,
            bus_data   => bus_data   ,
            dac_cs_n   => dac_cs_n   ,
            dac_sck    => dac_sck    ,
            dac_sdi    => dac_sdi    ,
            dac_ldac_n => dac_ldac_n ,
            enable5    => sw1        ,
            enable3    => sw2        ,
            test       => test
            );

    ------------------------------------------------
    -- GOP Specific Stuff
    ------------------------------------------------
    led <= (others => '0');

end Behavioral;
