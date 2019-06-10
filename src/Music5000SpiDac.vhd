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
        bus_data_oel: out  std_logic;
        dac_cs_n   : out   std_logic;
        dac_sck    : out   std_logic;
        dac_sdi    : out   std_logic;
        dac_ldac_n : out   std_logic;
        enable5    : in    std_logic;
        enable3    : in    std_logic;
        irq_n      : out   std_logic;
        test_o     : out   std_logic;
        owl        : in    std_logic := '1'
    );
end Music5000SpiDac;

architecture Behavioral of Music5000SpiDac is

signal audio5_l        : std_logic_vector(dacwidth - 1 downto 0);
signal audio5_r        : std_logic_vector(dacwidth - 1 downto 0);
signal audio3_l        : std_logic_vector(dacwidth - 1 downto 0);
signal audio3_r        : std_logic_vector(dacwidth - 1 downto 0);
signal audio_l         : std_logic_vector(dacwidth - 1 downto 0);
signal audio_r         : std_logic_vector(dacwidth - 1 downto 0);
signal dac_shift_reg_l : std_logic_vector(dacwidth - 1 downto 0);
signal dac_shift_reg_r : std_logic_vector(dacwidth - 1 downto 0);
signal cycle           : std_logic_vector(6 downto 0);
signal din             : std_logic_vector(7 downto 0);
signal dout3           : std_logic_vector(7 downto 0);
signal dout3_oel       : std_logic;
signal dout5           : std_logic_vector(7 downto 0);
signal dout5_oel       : std_logic;

signal owl_dout        : std_logic_vector(7 downto 0);
signal owl_oel         : std_logic;
signal owl_page        : std_logic;

begin

    ------------------------------------------------
    -- OWL Logo Test
    -- (this is used in all my standalone M5K designs)
    ------------------------------------------------

    bus_interface_fc : process(clke)
    begin
        if falling_edge(clke) then
            if rst_n = '0' then
                if owl = '1' then
                    owl_page  <= '1';
                    irq_n <= '0';
                else
                    owl_page  <= '0';
                    irq_n <= '1';
                end if;
            elsif pgfc_n = '0' and bus_addr = x"ff" then
                if rnw = '0' then
                    owl_page  <= '0';
                else
                    irq_n <= '1';
                end if;
            end if;
        end if;
    end process;

    inst_OwlRom : entity work.OwlRom
        port map (
            clock   => clke,     -- rising edge
            address => bus_addr,
            data    => owl_dout
            );

    owl_oel <= '0' when pgfd_n = '0' and rnw = '1' and owl_page = '1' else '1';

    ------------------------------------------------
    -- Music 5000 Core
    -- (this is shared with BeebFPGA)
    ------------------------------------------------

    inst_Music5000 : entity work.Music5000
        generic map (
            sumwidth => sumwidth,
            dacwidth => dacwidth,
            id       => "0011"
            )
        port map (
            -- This is the cpu clock
            clk      => not clke  ,
            clken    => '1'       ,
            -- This is the 6MHz audio clock
            clk6     => clk6      ,
            clk6en   => '1'       ,
            rnw      => rnw       ,
            rst_n    => rst_n     ,
            pgfc_n   => pgfc_n    ,
            pgfd_n   => pgfd_n    ,
            a        => bus_addr  ,
            din      => din       ,
            dout     => dout5     ,
            dout_oel => dout5_oel ,
            audio_l  => audio5_l  ,
            audio_r  => audio5_r  ,
            cycle    => cycle     ,
            test     => open
            );

    inst_Music3000 : entity work.Music5000
        generic map (
            sumwidth => sumwidth,
            dacwidth => dacwidth,
            id       => "0101"
            )
        port map (
            -- This is the cpu clock
            clk      => not clke  ,
            clken    => '1'       ,
            -- This is the 6MHz audio clock
            clk6     => clk6      ,
            clk6en   => '1'       ,
            rnw      => rnw       ,
            rst_n    => rst_n     ,
            pgfc_n   => pgfc_n    ,
            pgfd_n   => pgfd_n    ,
            a        => bus_addr  ,
            din      => din       ,
            dout     => dout3     ,
            dout_oel => dout3_oel ,
            audio_l  => audio3_l  ,
            audio_r  => audio3_r  ,
            cycle    => open      ,
            test     => open
            );

    din <= bus_data;

    bus_data <= owl_dout when owl_oel = '0'   else
                dout5    when dout5_oel = '0' else
                dout3    when dout3_oel = '0' else
                (others => 'Z');

    bus_data_oel <= '0' when rnw = '0' else
                    '0' when owl_oel = '0' or dout5_oel = '0' or dout3_oel = '0' else
                    '1';

    ------------------------------------------------
    -- Audio Mixer
    -- (between Music5000 and Music3000 output)
    ------------------------------------------------
    mixer : process(enable5, enable3, audio5_l, audio5_r, audio3_l, audio3_r)
        variable tmp_l : signed(dacwidth - 1 downto 0);
        variable tmp_r : signed(dacwidth - 1 downto 0);
    begin
        tmp_l := (others => '0');
        tmp_r := (others => '0');
        if (enable5 = '1') then
            tmp_l := tmp_l + signed(audio5_l);
            tmp_r := tmp_r + signed(audio5_r);
        end if;
        if (enable3 = '1') then
            tmp_l := tmp_l + signed(audio3_l);
            tmp_r := tmp_r + signed(audio3_r);
        end if;
        audio_l <= std_logic_vector(tmp_l);
        audio_r <= std_logic_vector(tmp_r);
    end process;

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
