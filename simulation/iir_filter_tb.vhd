library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iir_filter_tb is
    generic (
        dacwidth : integer := 18
    );
end iir_filter_tb;

architecture Behavioral of iir_filter_tb is

    -- Step input of from 0 to +/- 90% full scale value
    constant step          : integer := (2 ** (dacwidth - 1)) * 90 / 100;

    signal audio_l         : std_logic_vector(dacwidth - 1 downto 0) := (others => '0');
    signal audio_r         : std_logic_vector(dacwidth - 1 downto 0) := (others => '0');
    signal audio_l_fout    : std_logic_vector(dacwidth - 1 downto 0);
    signal audio_r_fout    : std_logic_vector(dacwidth - 1 downto 0);
    signal filt_load       : std_logic := '0';
    signal clk6            : std_logic := '0';
    signal counter         : unsigned(11 downto 0) := (others => '0');

begin

    clk6 <= not clk6 after 83.333 ns;

    process(clk6)
    begin
        if rising_edge(clk6) then
            counter <= counter + 1;
            if counter(6 downto 0) = "0000000" then
                filt_load <= '1';
            else
                filt_load <= '0';
            end if;
            if counter = x"100" then
                audio_l <= std_logic_vector(to_signed(step, dacwidth));
                audio_r <= std_logic_vector(to_signed(-step, dacwidth));
            end if;
        end if;
    end process;

    process(filt_load)
    begin
        if rising_edge(filt_load) then
            report
                integer'image(to_integer(signed(audio_l_fout))) & " " &
                integer'image(to_integer(signed(audio_r_fout)));
        end if;
    end process;

    iir_filter_inst : entity work.iir_filter
        port map (
            clk  => clk6,
            load => filt_load,
            lin  => audio_l,
            lout => audio_l_fout,
            rin  => audio_r,
            rout => audio_r_fout
            );

end Behavioral;
