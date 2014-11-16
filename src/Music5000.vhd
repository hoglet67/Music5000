----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:11:42 11/15/2014 
-- Design Name: 
-- Module Name:    Music5000 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library unisim;
use unisim.vcomponents.all;

entity Music5000 is
    generic (
        sumwidth : integer := 19;
        dacwidth : integer := 11
    );    
    port (
        clk49152 : in     std_logic;
        clke     : in     std_logic;
        rnw      : in     std_logic;
        rst_n    : in     std_logic;
        pgfc_n   : in     std_logic;
        pgfd_n   : in     std_logic;
        bus_addr : in     std_logic_vector (7 downto 0);
        bus_data : inout  std_logic_vector (7 downto 0);
        audio_l  : out    std_logic;
        audio_r  : out    std_logic;
        test     : out    std_logic
    );
end music5000;

architecture Behavioral of Music5000 is

--component DCM0
--    port (
--        CLKIN_IN  : in  std_logic;
--        CLK0_OUT  : out std_logic;
--        CLK0_OUT1 : out std_logic;
--        CLK2X_OUT : out std_logic
--    ); 
--end component;

	COMPONENT DCM1
	PORT(
		CLKIN_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic
		);
	END COMPONENT;
    
	COMPONENT DCM2
	PORT(
		CLKIN_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic
		);
	END COMPONENT;

component Ram2K
    port (
        clka  : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(10 downto 0);
        dina  : in  std_logic_vector(7 downto 0);
        douta : out std_logic_vector(7 downto 0);
        clkb  : in  std_logic;
        web   : in  std_logic;
        addrb : in  std_logic_vector(10 downto 0);
        dinb  : in  std_logic_vector(7 downto 0);
        doutb : out std_logic_vector(7 downto 0)
        );
end component;

component LogLinRom
    port (
        CLK  : in  std_logic;
        ADDR : in  std_logic_vector(6 downto 0);
        DATA : out std_logic_vector(12 downto 0)
        );
end component;

component pwm_sddac
  generic (
    msbi_g : integer := 8
  );
  port (
    clk_i   : in  std_logic;
    reset   : in  std_logic;
    dac_i   : in  std_logic_vector(msbi_g downto 0);
    dac_o   : out std_logic
  );
end component;

signal clk6 : std_logic;
signal clk23783 : std_logic;
signal clk49 : std_logic;
signal clkdac : std_logic;
signal clkctr : std_logic_vector (1 downto 0);

signal sum : std_logic_vector (8 downto 0);
signal a : std_logic_vector (7 downto 0);
signal b : std_logic_vector (7 downto 0);

signal ram_din : std_logic_vector (7 downto 0);
signal ram_dout : std_logic_vector (7 downto 0);
signal host_addr : std_logic_vector (7 downto 0);
signal ram_addr : std_logic_vector (10 downto 0);
signal ram_we : std_logic;
signal wave_dout : std_logic_vector (7 downto 0);
signal wave_addr : std_logic_vector (10 downto 0);

signal phase_we : std_logic;
signal phase_addr : std_logic_vector (10 downto 0);
signal phase_dout : std_logic_vector (7 downto 0);

signal addr : std_logic_vector (6 downto 0);
signal pa   : std_logic_vector (2 downto 1);

signal s0_n : std_logic;
signal s1_n : std_logic;
signal s4_n : std_logic;
signal s6_n : std_logic;
signal s7_n : std_logic;
signal sx_n : std_logic;
signal index : std_logic;
signal invert : std_logic;
signal c0 : std_logic_vector(0 downto 0);
signal c4 : std_logic;
signal c4tmp : std_logic;
signal c4d : std_logic;
signal sign : std_logic;
signal gate_n: std_logic;
signal load : std_logic;

signal dac_input_log : std_logic_vector (6 downto 0);
signal dac_input_lin : std_logic_vector (12 downto 0);
signal dac_input_lin_l : signed (sumwidth - 1 downto 0);
signal dac_input_lin_r : signed(sumwidth - 1 downto 0);
signal dac_input_lin_l1 : signed (dacwidth - 1 downto 0);
signal dac_input_lin_r1 : signed(dacwidth - 1 downto 0);
signal dac_pos : std_logic_vector (3 downto 0);
signal dac_sign : std_logic;
signal dac_sb : std_logic;
signal dac_ed : std_logic;

signal reg_s0 : std_logic_vector (3 downto 0);
signal reg_s4 : std_logic_vector (3 downto 0);

-- bits of address fcff
signal wrg_n : std_logic;
signal bank : std_logic_vector(2 downto 0);

begin

--    Inst_DCM0 : DCM0
--        port map (
--            CLKIN_IN => clk49,
--            CLK0_OUT => clk6,
--            CLK0_OUT1 => open,
--            CLK2X_OUT => open
--        );

	Inst_DCM1: DCM1 PORT MAP(
		CLKIN_IN => clk49152,
		CLKFX_OUT => clk23783,
		CLKIN_IBUFG_OUT => clk49,
		CLK0_OUT => open
	);

	Inst_DCM2: DCM2 PORT MAP(
		CLKIN_IN => clk49,
		CLKFX_OUT => clkdac,
		CLK0_OUT => open
	);

    clock_divider : process(clk23783, rst_n)
    begin
        if rising_edge(clk23783) then
            clkctr <= std_logic_vector(unsigned(clkctr) + 1);
        end if;
    end process;
    
    clk6 <= clkctr(1);
    ------------------------------------------------
    -- Bus Interface
    ------------------------------------------------

    bus_interface_fc : process(clke, rst_n)
    begin
        if rst_n = '0' then
            wrg_n <= '0';
            bank <= (others => '0');
        elsif rising_edge(clke) then
            if (pgfc_n = '0' and bus_addr = "11111111" and rnw = '0') then
                if (bus_data(7 downto 4) = "0011") then
                    wrg_n <= '0';
                else
                    wrg_n <= '1';
                end if;
                bank <= bus_data(3 downto 1);
            end if;
        end if;
    end process;

    bus_interface_fd_rising : process(clke, rst_n)
    begin
        if rst_n = '0' then
            ram_we <= '0';
            host_addr <= (others => '0');
        elsif rising_edge(clke) then
            if (pgfd_n = '0' and rnw = '0' and wrg_n = '0') then
                ram_we <= '1';
                host_addr <= bus_addr;
            else
                ram_we <= '0';
            end if;
        end if;
    end process;

    bus_interface_fd_falling : process(clke)
    begin
        if falling_edge(clke) then
            ram_din <= bus_data;
        end if;
    end process;



    ram_addr <= bank & bus_addr when ram_we = '0' else
                 bank & host_addr;
                 
    
    bus_data <= wrg_n & "000" & bank & '0' when pgfc_n = '0' and rnw = '1' 
                 else ram_dout when pgfd_n = '0' and rnw = '1'
                 else (others => 'Z');
          
    
    ------------------------------------------------
    -- Controller RAM
    ------------------------------------------------

    controller_sync : process(clk6, rst_n)
    begin
        if rst_n = '0' then
            addr <= (others => '0');
            pa <= (others => '0');
            reg_s0 <= (others => '0');
            reg_s4  <= (others => '0');
            index <= '0';
        elsif rising_edge(clk6) then
            addr <= std_logic_vector(unsigned(addr) + 1);
            pa(2 downto 1) <= addr(2 downto 1);
            if (s0_n = '0') then
              reg_s0 <= wave_dout(7) & (c4d or sign) & wave_dout(5 downto 4);
            end if;
            if (s4_n = '0') then
              reg_s4 <= wave_dout(7 downto 4);
            end if;
            if (s7_n = '0') then
              index <= reg_s0(1) and reg_s0(2);
            end if;
        end if;
     end process;

    invert <= reg_s0(0);
    
    s0_n <= '0' when addr(2 downto 0) = "000" else '1';
    s1_n <= '0' when addr(2 downto 0) = "001" else '1';
    s4_n <= '0' when addr(2 downto 0) = "100" else '1';
    s6_n <= '0' when addr(2 downto 0) = "110" else '1';
    s7_n <= '0' when addr(2 downto 0) = "111" else '1';
    sx_n <= '0' when c4tmp = '1' and s7_n = '0' else '1';

    ------------------------------------------------
    -- Wave RAM
    ------------------------------------------------

    wave_addr <= reg_s4 & sum(7 downto 1) when s6_n = '0' else
                 "111" & index & addr(0) & addr(2) & addr(1) & addr(3) & addr(6) & addr(5) & addr(4);
            
    inst_WaveRam : Ram2K
        port map (
            -- port A connects to 1MHz Bus
            clka  => clke,
            wea   => ram_we,
            addra => ram_addr,
            dina  => ram_din,
            douta => ram_dout,
            -- port B connects to DSP
            clkb  => clk6,
            web   => '0',
            addrb => wave_addr,
            dinb  => (others => '0'),
            doutb => wave_dout
            );

    ------------------------------------------------
    -- Phase RAM
    ------------------------------------------------
            
    phase_we <= s0_n and not (sx_n and addr(0));
    phase_addr <= "00000" & addr(6 downto 3) & pa(2 downto 1);

    inst_PhaseRam : Ram2K
        port map (
            -- port A connects to 1MHz Bus
            clka  => clk6,
            wea   => phase_we,
            addra => phase_addr,
            dina  => sum(7 downto 0),
            douta => phase_dout,
            -- port B is not used
            clkb  => '0',
            web   => '0',
            addrb => (others => '0'),
            dinb  => (others => '0'),
            doutb => open
            );


    ------------------------------------------------
    -- ALU
    ------------------------------------------------

    alu_sync : process(clk6)
    begin
        if rising_edge(clk6) then
            c4tmp <= c4;
            c4d <= c4tmp;
            a <= wave_dout;
            if (s1_n = '0') then
              load <= wave_dout(0);
            elsif (s7_n = '0') then
              load <= '0';
            end if;
        end if;
    end process;

    c0(0) <= addr(2) and c4d;
    b <= phase_dout when addr(0) = '0' and load = '0'
         else (others => '0');                   
    sum <= std_logic_vector(unsigned("0" & a) + unsigned("0" & b) + unsigned("00000000" & c0));
    c4 <= sum(8);
    sign <= a(7);
    gate_n <= sum(7) xnor sign;

    ------------------------------------------------
    -- Wave Positioner
    ------------------------------------------------

    pos_sync : process(clk6)
    begin
        if rising_edge(clk6) then
            if (s0_n = '0' and gate_n = '0') then
                dac_input_log <= sum(6 downto 0);
                dac_sign <= sign;
                dac_pos <= wave_dout(3 downto 0);
            elsif (s6_n <= '0') then
                dac_input_log <= (others => '0');
                dac_sign <= '0'; 
                dac_pos <= (others => '0');
            elsif (dac_pos(3) = '1') then
                dac_pos <= std_logic_vector(unsigned(dac_pos) + 1);
            end if;
            -- Delay these by one clock, to componsate for ROM delay
            dac_sb <= dac_sign xor invert;
            dac_ed <= dac_pos(3);
        end if;
    end process;
    

    ------------------------------------------------
    -- DAC log to linear convertor
    ------------------------------------------------

    inst_LogLinRom : LogLinRom
        port map (
          CLK  => clk6,
          ADDR => dac_input_log,
          DATA => dac_input_lin
       );
          
    ------------------------------------------------
    -- Mixer
    ------------------------------------------------
    
    mixer_sync : process(clk6)
    begin
        if rising_edge(clk6) then
            -- Todo: this expression may not be correct
            if (addr = "0000001") then
                dac_input_lin_l <= (others => '0');
                dac_input_lin_r <= (others => '0');
                dac_input_lin_l(sumwidth - 1) <= '1';
                dac_input_lin_r(sumwidth - 1) <= '1';
                dac_input_lin_l1 <= dac_input_lin_l(sumwidth - 1 downto sumwidth - dacwidth); 
                dac_input_lin_r1 <= dac_input_lin_r(sumwidth - 1 downto sumwidth - dacwidth); 
            else
                if dac_ed = '1' then
                    if dac_sb = '1' then
                        dac_input_lin_l <= dac_input_lin_l - signed("0" & dac_input_lin);                
                    else
                        dac_input_lin_l <= dac_input_lin_l + signed("0" & dac_input_lin);                
                    end if;
                else
                    if dac_sb = '1' then
                        dac_input_lin_r <= dac_input_lin_r - signed("0" & dac_input_lin);                
                    else
                        dac_input_lin_r <= dac_input_lin_r + signed("0" & dac_input_lin);                
                    end if;
                end if;
            end if;
        end if;
    end process;    

    ------------------------------------------------
    -- DACs
    ------------------------------------------------
    
    dac_l : pwm_sddac
    generic map(
        msbi_g => dacwidth - 1
    )
	port map(
		clk_i				=> clkdac,
		reset				=> not rst_n,
		dac_i				=> std_logic_vector(dac_input_lin_l1),
		dac_o				=> audio_l
	);

    dac_r : pwm_sddac
    generic map(
        msbi_g => dacwidth - 1
    )
	port map(
		clk_i				=> clkdac,
		reset				=> not rst_n,
		dac_i				=> std_logic_vector(dac_input_lin_r1),
		dac_o				=> audio_r
	);
    
   
    ------------------------------------------------
    -- Test
    ------------------------------------------------
    test <= ram_we;

    
end Behavioral;

