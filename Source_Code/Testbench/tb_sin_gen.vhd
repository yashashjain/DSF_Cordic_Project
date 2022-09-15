----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.04.2022 12:54:38
-- Design Name: 
-- Module Name: tb_sin_gen - Behavioral
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
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_sin_gen is
    --  Port ( );
end tb_sin_gen;

architecture Behavioral of tb_sin_gen is
    component sin_gen_top
        Port(clk: in std_logic ;
             rst: in std_logic ;
             freq_reg: in unsigned (10 downto 0);
             cs : out std_logic;
             data : out std_logic;
             sclk : out std_logic);    end component;

    signal data,cs,sclk : std_logic;
    signal rst, clk: std_logic :='0';
    signal freq_reg: unsigned (10 downto 0) := (others => '0') ;

    constant period: time := 10 ns;
    constant setup: time := 0 ns;

begin
    uut: sin_gen_top
        PORT MAP (clk,rst,freq_reg,cs,data,sclk);
    process
    begin
        wait for 100 ns;
        cloop: loop
            clk <= '0';
            wait for (period/2);
            clk <= '1';
            wait for (period/2);
        end loop;
    end process;

    process
    begin
        wait for 100 ns;
        rst <= '1';
        wait for 100 ns;
        rst <= '0';

        wait for 50 us;
        freq_reg <= ("000"&x"01");
        wait for 50 us;
        freq_reg <= ("000"&x"01");
        wait for 10 us;
        freq_reg <= ("010"&x"FF");
        wait for 10 us;
        freq_reg <= ("000"&x"FF");
        wait;
    end process;
end Behavioral;
