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

    type rom_type is array (0 to 255) of std_logic_vector(7 downto 0);

    impure function InitRomFromFile (RomFileName : in string) return rom_type is
        use std.textio.all;
        use ieee.std_logic_textio.all;
        FILE romfile : text is in RomFileName;
        variable RomFileLine : line;
        variable rom : rom_type;
    begin
        for i in rom_type'range loop
            readline(romfile, RomFileLine);
            hread(RomFileLine, rom(i));
        end loop;
        return rom;
    end function;

    signal rom : rom_type := InitRomFromFile("../misc/owl/owl.dat");

begin

    process(clock) is
    begin
        if (rising_edge(clock)) then
            data <= rom(to_integer(unsigned(address)));
        end if;
    end process;

end RTL;
