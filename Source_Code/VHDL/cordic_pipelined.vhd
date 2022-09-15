----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.04.2022 12:10:09
-- Design Name: 
-- Module Name: cordic_pipelined - Behavioral
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
use ieee.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cordic_pipelined is
    generic (
        SIZE       : positive;
        ITERATIONS : positive;
        RESET_ACTIVE_LEVEL : std_ulogic := '1'
    );
    port (
        Clock : in std_ulogic;
        Reset : in std_ulogic;

        X : in signed(SIZE-1 downto 0);
        Y : in signed(SIZE-1 downto 0);
        Z : in signed(SIZE-1 downto 0);

        X_result : out signed(SIZE-1 downto 0);
        Y_result : out signed(SIZE-1 downto 0);
        Z_result : out signed(SIZE-1 downto 0)
    );
end cordic_pipelined;

architecture Behavioral of cordic_pipelined is

    type signed_pipeline is array (natural range <>) of signed(SIZE-1 downto 0);

    signal x_pl, y_pl, z_pl : signed_pipeline(1 to ITERATIONS);
    signal x_array, y_array, z_array : signed_pipeline(0 to ITERATIONS);

    function gen_atan_table(size : positive; iterations : positive) return signed_pipeline is
        variable table : signed_pipeline(0 to ITERATIONS-1);
    begin
        for i in table'range loop
            table(i) := to_signed(integer(arctan(2.0**(-i)) * 2.0**size / MATH_2_PI), size);
        end loop;

        return table;
    end function;

    constant ATAN_TABLE : signed_pipeline(0 to ITERATIONS-1) := gen_atan_table(SIZE, ITERATIONS);
begin

    x_array <= X & x_pl;
    y_array <= Y & y_pl;
    z_array <= Z & z_pl;

    cordic: process(Clock, Reset) is
        variable negative : boolean;
    begin
        if Reset = RESET_ACTIVE_LEVEL then
            x_pl <= (others => (others => '0'));
            y_pl <= (others => (others => '0'));
            z_pl <= (others => (others => '0'));

        elsif rising_edge(Clock) then
            for i in 1 to ITERATIONS loop
                negative := z_array(i-1)(z'high) = '1';



                --if z_array(i-1)(z'high) = '1' then -- z is negative
                if negative then
                    x_pl(i) <= x_array(i-1) + (y_array(i-1) / 2**(i-1));
                    y_pl(i) <= y_array(i-1) - (x_array(i-1) / 2**(i-1));
                    z_pl(i) <= z_array(i-1) + ATAN_TABLE(i-1);
                else -- z or y is positive
                    x_pl(i) <= x_array(i-1) - (y_array(i-1) / 2**(i-1));
                    y_pl(i) <= y_array(i-1) + (x_array(i-1) / 2**(i-1));
                    z_pl(i) <= z_array(i-1) - ATAN_TABLE(i-1);
                end if;
            end loop;
        end if;
    end process;

    X_result <= x_array(x_array'high);
    Y_result <= y_array(y_array'high);
    Z_result <= z_array(z_array'high);


end Behavioral;
