library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Ram2K is
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(10 downto 0);
        dina  : in  std_logic_vector(7 downto 0);
        douta : out std_logic_vector(7 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        web   : in  std_logic;
        addrb : in  std_logic_vector(10 downto 0);
        dinb  : in  std_logic_vector(7 downto 0);
        doutb : out std_logic_vector(7 downto 0)
        );
end Ram2K;

architecture BEHAVIORAL of Ram2K is

-- Shared memory
    type ram_type is array (2047 downto 0) of std_logic_vector (7 downto 0);
    shared variable RAM : ram_type;

--attribute RAM_STYLE : string;
--attribute RAM_STYLE of RAM: signal is "BLOCK";

begin

    process (clka)
    begin
        if rising_edge(clka) then
            if (ena = '1') then
                if (wea = '1') then
                    RAM(conv_integer(addra(10 downto 0))) := dina;
                end if;
                douta <= RAM(conv_integer(addra(10 downto 0)));
            end if;
        end if;
    end process;

    process (clkb)
    begin
        if rising_edge(clkb) then
            if (enb = '1') then
                if (web = '1') then
                    RAM(conv_integer(addrb(10 downto 0))) := dinb;
                end if;
                doutb <= RAM(conv_integer(addrb(10 downto 0)));
            end if;
        end if;
    end process;

end BEHAVIORAL;
