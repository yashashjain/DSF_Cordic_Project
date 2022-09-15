----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.04.2022 10:45:45
-- Design Name: 
-- Module Name: sin_gen_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sin_gen_top is
    Port(clk: in std_logic ;
         rst: in std_logic ;
         freq_reg: in unsigned (10 downto 0);
         cs : out std_logic;
         data : out std_logic;
         sclk : out std_logic);
end sin_gen_top;

architecture Behavioral of sin_gen_top is
    constant ITERATIONS : positive := 8;
    signal angle_in : signed (11 downto 0);
    signal sin_out : signed (11 downto 0);
    signal dac_in : unsigned  (11 downto 0);
    signal start_dac, clk_slow,clk_10 : std_logic;
    signal count : integer;

    component sincos_pipelined is
        generic (
            SIZE       : positive;    --# Width of operands
            ITERATIONS : positive;    --# Number of iterations for CORDIC algorithm
            FRAC_BITS  : positive;    --# Total fractional bits
            MAGNITUDE  : real := 1.0; --# Scale factor for vector length
            RESET_ACTIVE_LEVEL : std_ulogic := '1' --# Asynch. reset control level
        );
        port (
            --# {{clocks|}}
            Clock : in std_ulogic; --# System clock
            Reset : in std_ulogic; --# Asynchronous reset

            --# {{control|}}
            Angle : in signed(SIZE-1 downto 0); --# Angle in brads (2**SIZE brads = 2*pi radians)

            --# {{data|}}
            Sin   : out signed(SIZE-1 downto 0);  --# Sine of Angle
            Cos   : out signed(SIZE-1 downto 0)   --# Cosine of Angle
        );
    end component;

    component spi_dac
        generic (
            SIZE       : positive       -- Width of parameters
        );
        port (
            clk_in : in std_logic;
            rst : in std_logic;
            datain : in unsigned (11 downto 0);
            start : in std_logic;
            data   : out std_logic;
            cs   : out std_logic;
            sclk : out std_logic
        );
    end component;

    component clk_wiz_0
        port
(-- Clock in ports
        -- Clock out ports
            clk_out1          : out    std_logic;
            clk_in1           : in     std_logic
        );
    end component;

begin

    sin_comp: sincos_pipelined
        generic map (
            SIZE       => 12,
            ITERATIONS => 12,
            FRAC_BITS  => 11
        )
        port map (
            Clock => clk_slow,
            Reset => rst,

            Angle => angle_in,

            Sin => sin_out,
            Cos => Open
        );

    clk_pll : clk_wiz_0
        port map (
            -- Clock out ports  
            clk_out1 => clk_10,
            -- Clock in ports
            clk_in1 => clk
        );

    dac_itc: spi_dac
        generic map(
            SIZE       =>12       -- Width of parameters
        )
        port map (
            clk_in => clk_10,
            rst => rst,
            datain => dac_in,
            start => clk_slow,
            data => data,
            cs   => cs,
            sclk => sclk
        );

    process (clk_10)
    begin
        if (clk_10'event and clk_10 ='1') then
            if (rst = '1') then
                angle_in  <= (others => '0');
                clk_slow <= '0';
                count <= 0;
            else
                count <= count +1;
                if (count>8) then
                    count <=0;
                    clk_slow <= not clk_slow;
                    if clk_slow = '1' then
                        angle_in <= angle_in + signed("0"&freq_reg)+1;
                        dac_in <= unsigned(sin_out+x"800");
                    end if;
                end if;

            end if;
        end if;
    end process;


end Behavioral;
