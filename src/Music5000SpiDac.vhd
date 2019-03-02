library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Music5000SpiDac is
    generic (
        sumwidth : integer := 19;
        dacwidth : integer := 16
    );
    port (
        -- This is the 6MHz audio clock
        clk6       : in    std_logic;
        -- This is the cpu clock
        clke       : in    std_logic;
        rnw        : in    std_logic;
        rst_n      : in    std_logic;
        pgfc_n     : in    std_logic;
        pgfd_n     : in    std_logic;
        bus_addr   : in    std_logic_vector (7 downto 0);
        bus_data   : inout std_logic_vector (7 downto 0);
        dac_cs_n   : out   std_logic;
        dac_sck    : out   std_logic;
        dac_sdi    : out   std_logic;
        dac_ldac_n : out   std_logic;
        test       : out   std_logic
    );
end music5000SpiDac;

architecture Behavioral of Music5000SpiDac is

signal audio_l         : std_logic_vector(dacwidth - 1 downto 0);
signal audio_r         : std_logic_vector(dacwidth - 1 downto 0);
signal dac_shift_reg_l : std_logic_vector(dacwidth - 1 downto 0);
signal dac_shift_reg_r : std_logic_vector(dacwidth - 1 downto 0);
signal cycle           : std_logic_vector(6 downto 0);
signal din             : std_logic_vector(7 downto 0);
signal dout            : std_logic_vector(7 downto 0);
signal dout_oel        : std_logic;

begin

    ------------------------------------------------
    -- Music 5000 Core
    -- (this is shared with BeebFPGA)
    ------------------------------------------------

    inst_Music5000Core : entity work.Music5000
        generic map (
            sumwidth => sumwidth,
            dacwidth => dacwidth,
            id       => "0011"
            )
        port map (
            -- This is the cpu clock
            clk      => clke     ,
            clken    => '1'    ,
            -- This is the 6MHz audio clock
            clk6     => clk6     ,
            clk6en   => '1'   ,
            rnw      => rnw      ,
            rst_n    => rst_n    ,
            pgfc_n   => pgfc_n   ,
            pgfd_n   => pgfd_n   ,
            a        => bus_addr ,
            din      => din      ,
            dout     => dout     ,
            dout_oel => dout_oel ,
            audio_l  => audio_l  ,
            audio_r  => audio_r  ,
            cycle    => cycle    ,
            test     => test
            );

    din <= bus_data;

    bus_data <= dout when dout_oel = '0' else (others => 'Z');

    ------------------------------------------------
    -- SPI DAC
    -- (this is used in all my standalone M5K designs)
    ------------------------------------------------

dac_sync : process(clk6)
    begin
        if rising_edge(clk6) then

            if (unsigned(cycle(5 downto 0)) < 33) then
                dac_cs_n <= '0';
                dac_sck <= cycle(0);
            else
                dac_cs_n <= '1';
                dac_sck <= '0';
            end if;

            if (cycle(0) = '0') then
                if (unsigned(cycle(5 downto 1)) = 0) then
                    if (cycle(6) = '0') then
                        dac_shift_reg_l(dacwidth - 2 downto 0) <= audio_l(dacwidth - 2 downto 0);
                        dac_shift_reg_l(dacwidth - 1)          <= not audio_l(dacwidth - 1);
                        dac_shift_reg_r(dacwidth - 2 downto 0) <= audio_r(dacwidth - 2 downto 0);
                        dac_shift_reg_r(dacwidth - 1)          <= not audio_r(dacwidth - 1);
                    end if;
                    dac_sdi <= cycle(6);
                elsif (unsigned(cycle(5 downto 1)) < 4) then
                    dac_sdi <= '1';
                elsif (unsigned(cycle(5 downto 1)) < 16) then
                    if (cycle(6) = '0') then
                        dac_sdi <= dac_shift_reg_l(dacwidth - 1);
                        dac_shift_reg_l <= dac_shift_reg_l(dacwidth - 2 downto 0) & '0';
                    else
                        dac_sdi <= dac_shift_reg_r(dacwidth - 1);
                        dac_shift_reg_r <= dac_shift_reg_r(dacwidth - 2 downto 0) & '0';
                    end if;
                else
                    dac_sdi <= '0';
                end if;
                if (unsigned(cycle(6 downto 1)) = 60) then
                    dac_ldac_n <= '0';
                else
                    dac_ldac_n <= '1';
                end if;
            end if;
        end if;
     end process;

end Behavioral;
