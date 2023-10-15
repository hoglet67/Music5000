library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity iir_filter is
    generic (
        W_IO        : integer := 18; -- Width of external data inputs/outputs
        W_DAT       : integer := 25; -- Width of internal data data nodes, giving headroom for filter gail
        W_SUM       : integer := 48; -- Width of internal summers
        W_COEFF     : integer := 18; -- Width of coefficients
        W_FRAC      : integer := 15  -- Width of fractional part of coefficients
        );
    port (
        clk         : in  std_logic;
        load        : in  std_logic;
        lin         : in  std_logic_vector(W_IO - 1 downto 0);
        lout        : out std_logic_vector(W_IO - 1 downto 0);
        rin         : in  std_logic_vector(W_IO - 1 downto 0);
        rout        : out std_logic_vector(W_IO - 1 downto 0)
       );
end iir_filter;

architecture Behavioral of iir_filter is

    signal state : unsigned(6 downto 0) := (others => '0');

    signal lin0  : signed(W_DAT - 1 downto 0) := (others => '0');
    signal lin1  : signed(W_DAT - 1 downto 0) := (others => '0');
    signal lin2  : signed(W_DAT - 1 downto 0) := (others => '0');
    signal ltmp0 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal ltmp1 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal ltmp2 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal lout0 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal lout1 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal lout2 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rin0  : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rin1  : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rin2  : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rtmp0 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rtmp1 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rtmp2 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rout0 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rout1 : signed(W_DAT - 1 downto 0) := (others => '0');
    signal rout2 : signed(W_DAT - 1 downto 0) := (others => '0');

    signal multa : signed(W_COEFF - 1 downto 0);
    signal multb : signed(W_DAT - 1 downto 0);
    signal multbx : signed(W_COEFF - 1 downto 0);
    signal multout : signed(W_COEFF + W_COEFF - 1 downto 0);
    signal sum : signed(W_SUM - 1 downto 0);
    signal sum_shifted : signed(W_SUM - W_FRAC - 1 downto 0);
    signal sum_saturated : signed(W_DAT - 1 downto 0);

    constant MAX_NEG : signed(W_DAT - 1 downto 0) := ('1', others => '0');
    constant MAX_POS : signed(W_DAT - 1 downto 0) := ('0', others => '1');

    constant SUM_ZERO : signed(W_SUM - 1 downto 0) := (others => '0');

    -- http://jaggedplanet.com/iir/iir-explorer.asp
    --
    -- Butterworth, Low-pass, Order 3, Sample rate 46875, Cutoff 3214
    --
    -- REAL biquada[]={0.6545294918791053,-1.503352371060256,-0.640959826975052};
    -- REAL biquadb[]={1,2,1};
    -- REAL gain=147.38757472209932;
    -- REAL xyv[]={0,0,0,0,0,0,0,0,0};
    --
    -- REAL applyfilter(REAL v)
    -- {
    --   int i,b,xp=0,yp=3,bqp=0;
    --   REAL out=v/gain;
    --   for (i=8; i>0; i--) {xyv[i]=xyv[i-1];}
    --   for (b=0; b<NBQ; b++)
    --   {
    --     int len=(b==NBQ-1)?1:2;
    --     xyv[xp]=out;
    --     for(i=0; i<len; i++) { out+=xyv[xp+len-i]*biquadb[bqp+i]-xyv[yp+len-i]*biquada[bqp+i]; }
    --     bqp+=len;
    --     xyv[yp]=out;
    --     xp=yp; yp+=len+1;
    --   }
    --   return out;
    -- }
    --                 b12                 b11                b21
    -- REAL biquadb[]={1,                  2,                 1};
    -- REAL biquada[]={0.6545294918791053,-1.503352371060256,-0.640959826975052};
    --                 a12                 a11                a21
    --
    -- Note, the sign of axx coefficients needs flipping, as our
    -- implementation adds rather than subtracts these
    --
    -- BiQuad 1: 2nd Order b10=1 b11=2 b12=1 a11=1.503352371060256 a12=-0.6545294918791053
    -- BiQuad 2: 1st Order b20=1 b21=1 b22=0 a21=0.640959826975052 a12=0
    --
    -- Gain is 147.38757472209932 which is taken account of currently
    -- because W_DAT - W_IO = 7, so the final output is attenuated by 128.

    constant b10 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 1.0                * (2.0 ** W_FRAC)), W_COEFF);
    constant b11 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 2.0                * (2.0 ** W_FRAC)), W_COEFF);
    constant b12 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 1.0                * (2.0 ** W_FRAC)), W_COEFF);
    constant a11 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 1.503352371060256  * (2.0 ** W_FRAC)), W_COEFF);
    constant a12 : signed(W_COEFF - 1 downto 0) := to_signed(integer(-0.6545294918791053 * (2.0 ** W_FRAC)), W_COEFF);

    constant b20 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 1.0                * (2.0 ** W_FRAC)), W_COEFF);
    constant b21 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 1.0                * (2.0 ** W_FRAC)), W_COEFF);
    constant b22 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 0.0                * (2.0 ** W_FRAC)), W_COEFF);
    constant a21 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 0.640959826975052  * (2.0 ** W_FRAC)), W_COEFF);
    constant a22 : signed(W_COEFF - 1 downto 0) := to_signed(integer( 0.0                * (2.0 ** W_FRAC)), W_COEFF);

    -- State
    --
    -- 00 - idle
    -- 01 - load       lin2  * b12
    -- 02 - accumulate lin1  * b11
    -- 03 - accumulate lin0  * b10
    -- 04 - accumulate ltmp2 * a12
    -- 05 - accumulate ltmp1 * a11
    -- 06 - pipeline
    -- 07 - pipeline
    -- 08 - shift, saturate, store result in ltmp0
    -- 09 - load       ltmp2 * b22
    -- 0A - accumulate ltmp1 * b21
    -- 0B - accumulate ltmp0 * b20
    -- 0C - accumulate lout2 * a22
    -- 0D - accumulate lout1 * a21
    -- 0E - pipeline
    -- 0F - pipeline
    -- 10 - shift, saturate, store result in lout0
    -- 11
    -- .. - same for right channel
    -- 20

begin

    sum_shifted <= sum(W_SUM - 1 downto W_FRAC);

    sum_saturated <= MAX_POS when sum_shifted > MAX_POS else
                     MAX_NEG when sum_shifted < MAX_NEG else
                     sum_shifted(W_DAT - 1 downto 0);

    multbx <= multb(W_DAT - 1 downto W_DAT - W_COEFF) when state(0) = '0' else -- MSB
              resize('0' & multb(W_DAT - W_COEFF - 1 downto 0), W_COEFF);      -- LSB

    process(clk)
    begin
        if rising_edge(clk) then

            multout <= multa * multbx;

            if state(3 downto 0) = "0100" then
                sum <= SUM_ZERO + multout; -- load LSB
            elsif state(0) = '0' then
                sum <= sum + multout; -- accumulate LSB
				else
                sum <= sum + (multout & resize("0", W_DAT - W_COEFF)); -- accumulate MSB
            end if;

            -- Load / shift registers once per sample period
            if load = '1' then
                lin0  <= resize(signed(lin), W_DAT);
                lin1  <= lin0;
                lin2  <= lin1;
                ltmp1 <= ltmp0;
                ltmp2 <= ltmp1;
                lout1 <= lout0;
                lout2 <= lout1;
                rin0  <= resize(signed(rin), W_DAT);
                rin1  <= rin0;
                rin2  <= rin1;
                rtmp1 <= rtmp0;
                rtmp2 <= rtmp1;
                rout1 <= rout0;
                rout2 <= rout1;
            end if;

            -- Muliplier A input (coefficient)
            case state(4 downto 1) is
                when "0001" =>
                    multa <= b12;
                when "0010" =>
                    multa <= b11;
                when "0011" =>
                    multa <= b10;
                when "0100" =>
                    multa <= a12;
                when "0101" =>
                    multa <= a11;
                when "1001" =>
                    multa <= b22;
                when "1010" =>
                    multa <= b21;
                when "1011" =>
                    multa <= b20;
                when "1100" =>
                    multa <= a22;
                when "1101" =>
                    multa <= a21;
                when others =>
                    multa <= (others => '0');
            end case;

            -- Muliplier B input (coefficient)
            case state(6 downto 1) is
                when "000001" =>
                    multb <= lin2;
                when "000010" =>
                    multb <= lin1;
                when "000011" =>
                    multb <= lin0;
                when "000100" =>
                    multb <= ltmp2;
                when "000101" =>
                    multb <= ltmp1;
                when "001001" =>
                    multb <= ltmp2;
                when "001010" =>
                    multb <= ltmp1;
                when "001011" =>
                    multb <= ltmp0;
                when "001100" =>
                    multb <= lout2;
                when "001101" =>
                    multb <= lout1;
                when "010001" =>
                    multb <= rin2;
                when "010010" =>
                    multb <= rin1;
                when "010011" =>
                    multb <= rin0;
                when "010100" =>
                    multb <= rtmp2;
                when "010101" =>
                    multb <= rtmp1;
                when "011001" =>
                    multb <= rtmp2;
                when "011010" =>
                    multb <= rtmp1;
                when "011011" =>
                    multb <= rtmp0;
                when "011100" =>
                    multb <= rout2;
                when "011101" =>
                    multb <= rout1;
                when others =>
                    multb <= (others => '0');
            end case;

            if state(6 downto 0) = "0010000" then
                ltmp0 <= sum_saturated(W_DAT - 1 downto 0);
            end if;

            if state(6 downto 0) = "0100000" then
                lout0 <= sum_saturated(W_DAT - 1 downto 0);
            end if;

            if state(6 downto 0) = "0110000" then
                rtmp0 <= sum_saturated(W_DAT - 1 downto 0);
            end if;

            if state(6 downto 0) = "1000000" then
                rout0 <= sum_saturated(W_DAT - 1 downto 0);
            end if;

            if state(6 downto 0) = "1000001" then
                lout <= std_logic_vector(lout0(W_DAT - 1 downto W_DAT - W_IO));
                rout <= std_logic_vector(rout0(W_DAT - 1 downto W_DAT - W_IO));
            end if;

            if state = "0000000" then
                if load = '1' then
                    state <= "0000001";
                end if;
            elsif state < "1000001" then
                state <= state + 1;
            else
                state <= "0000000";
            end if;

        end if;
    end process;

end Behavioral;
