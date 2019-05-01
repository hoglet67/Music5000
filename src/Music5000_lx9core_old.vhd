library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity Music5000_lx9core_old is
    port (
        -- System oscillator
        clk50        : in    std_logic;
        -- BBC 1MHZ Bus
        clke         : in    std_logic;
        rnw          : in    std_logic;
        rst_n        : in    std_logic;
        pgfc_n       : in    std_logic;
        pgfd_n       : in    std_logic;
        bus_addr     : in    std_logic_vector (7 downto 0);
        bus_data     : inout std_logic_vector (7 downto 0);
        bus_data_dir : out   std_logic;
        bus_data_oel : out   std_logic;
        nmi          : out   std_logic;
        irq          : out   std_logic;
        -- SPI DAC
        dac_cs_n     : out   std_logic;
        dac_sck      : out   std_logic;
        dac_sdi      : out   std_logic;
        dac_ldac_n   : out   std_logic;
        -- RAM (unused)
        ram_addr     : out   std_logic_vector(18 downto 0);
        ram_data     : inout std_logic_vector(7 downto 0);
        ram_cel      : out   std_logic;
        ram_oel      : out   std_logic;
        ram_wel      : out   std_logic;
        -- Misc
        pmod0        : out   std_logic_vector(7 downto 0);
        pmod1        : out   std_logic_vector(7 downto 4);
        led          : out   std_logic
    );
end Music5000_lx9core_old;

architecture Behavioral of Music5000_lx9core_old is

signal clk6 : std_logic;
signal irq_n : std_logic;

begin

    ------------------------------------------------
    -- 6MHZ Clock Generation
    -- (from the 50.000MHZ Oscillator)
    ------------------------------------------------

    inst_DCM : DCM
        generic map (
            CLKFX_MULTIPLY   => 3,
            CLKFX_DIVIDE     => 25,
            CLKIN_PERIOD     => 20.000,
            CLK_FEEDBACK     => "NONE"
            )
        port map (
            CLKIN            => clk50,
            CLKFB            => '0',
            RST              => '0',
            DSSEN            => '0',
            PSINCDEC         => '0',
            PSEN             => '0',
            PSCLK            => '0',
            CLKFX            => clk6
            );

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
            enable5    => '1'        ,
            enable3    => '1'        ,
            irq_n      => irq_n
            );

    ------------------------------------------------
    -- 1MHZ Bus FPGA Adapter Specific Stuff
    ------------------------------------------------

    irq          <= not irq_n;
    nmi          <= '0';

    bus_data_oel <= '0' when pgfc_n = '0' or pgfd_n = '0' else '1';
    bus_data_dir <= rnw;

    ram_addr     <= (others => '0');
    ram_data     <= (others => '0');
    ram_cel      <= '1';
    ram_oel      <= '1';
    ram_wel      <= '1';

    pmod0        <= (others => '0');
    pmod1        <= (others => '0');

    led          <= not rst_n;

end Behavioral;
