library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OwlRom is
    port(
        clock    : in  std_logic;
        address  : in  std_logic_vector(7 downto 0);
        data     : out std_logic_vector(7 downto 0)
  );
end OwlRom;

architecture RTL of OwlRom is

    type mem_type is array (0 to 255) of unsigned(7 downto 0);

    constant mem : mem_type := (
        x"ad", x"ff", x"fc", x"a9", x"4c", x"8d", x"87", x"02", x"a9", x"13", x"8d", x"88",
        x"02", x"a9", x"fd", x"8d", x"89", x"02", x"60", x"a9", x"00", x"8d", x"87", x"02",
        x"ad", x"8d", x"02", x"f0", x"22", x"ad", x"19", x"03", x"48", x"ad", x"18", x"03",
        x"48", x"a2", x"00", x"bd", x"40", x"fd", x"f0", x"06", x"20", x"ee", x"ff", x"e8",
        x"d0", x"f5", x"a9", x"1f", x"20", x"ee", x"ff", x"68", x"20", x"ee", x"ff", x"68",
        x"20", x"ee", x"ff", x"60", x"1f", x"1e", x"01", x"91", x"e2", x"a6", x"e2", x"a2",
        x"e6", x"a6", x"e2", x"a2", x"e6", x"1f", x"1e", x"02", x"91", x"a8", x"b0", x"a9",
        x"a1", x"b0", x"b0", x"a9", x"a1", x"b8", x"1f", x"1e", x"03", x"93", x"e2", x"e6",
        x"e4", x"e0", x"e2", x"e0", x"e0", x"a6", x"e2", x"1f", x"1e", x"04", x"92", x"a8",
        x"b9", x"b9", x"b9", x"b9", x"20", x"20", x"20", x"a8", x"1f", x"1e", x"05", x"96",
        x"20", x"a2", x"e6", x"e6", x"e6", x"e4", x"20", x"20", x"e2", x"1f", x"1e", x"06",
        x"94", x"20", x"20", x"20", x"a9", x"b9", x"a9", x"b9", x"b0", x"a8", x"1f", x"1e",
        x"07", x"95", x"20", x"a4", x"a4", x"a6", x"a4", x"a6", x"a4", x"a2", x"e6", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"fd");

 begin

    process(clock) is
    begin
        if (rising_edge(clock)) then
            data <= std_logic_vector(mem(to_integer(unsigned(address))));
        end if;
    end process;

end RTL;
