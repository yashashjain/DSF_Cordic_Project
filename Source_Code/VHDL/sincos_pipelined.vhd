----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.04.2022 11:59:17
-- Design Name: 
-- Module Name: sincos_pipelined - Behavioral
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

entity sincos_pipelined is
    generic (
        SIZE       : positive;       -- Width of parameters
        ITERATIONS : positive; -- Number of CORDIC iterations
        FRAC_BITS  : positive;  -- Total fractional bits
        MAGNITUDE  : real := 1.0;
        RESET_ACTIVE_LEVEL : std_ulogic := '1'
    );
    port (
        Clock : in std_ulogic;
        Reset : in std_ulogic;

        --Load  : in std_ulogic;  -- Start processing a new angle value
        --Done  : out std_ulogic; -- Indicates when iterations are complete

        Angle : in signed(SIZE-1 downto 0); -- Angle in brads (2**SIZE brads = 2*pi radians)

        Sin   : out signed(SIZE-1 downto 0);  -- Sine of Angle
        Cos   : out signed(SIZE-1 downto 0)   -- Cosine of Angle
    );
end sincos_pipelined;

architecture Behavioral of sincos_pipelined is
    signal xa, ya, za : signed(Angle'range);
    
    component cordic_pipelined is
    generic (
      SIZE               : positive; --# Width of operands
      ITERATIONS         : positive; --# Number of iterations for CORDIC algorithm
      RESET_ACTIVE_LEVEL : std_ulogic := '1' --# Asynch. reset control level
    );
    port (
      --# {{clocks|}}
      Clock : in std_ulogic; --# System clock
      Reset : in std_ulogic; --# Asynchronous reset

      --# {{data|}}
      X : in signed(SIZE-1 downto 0); --# X coordinate
      Y : in signed(SIZE-1 downto 0); --# Y coordinate
      Z : in signed(SIZE-1 downto 0); --# Z coordinate (angle in brads)

      X_result : out signed(SIZE-1 downto 0); --# X result
      Y_result : out signed(SIZE-1 downto 0); --# Y result
      Z_result : out signed(SIZE-1 downto 0)  --# Z result
    );
  end component;
    
  --## Compute gain from CORDIC pseudo-rotations
    function cordic_gain(iterations : positive) return real is
        variable g : real := 1.0;
    begin
        for i in 0 to iterations-1 loop
            g := g * sqrt(1.0 + 2.0**(-2*i));
        end loop;
        return g;
    end function;

    procedure adjust_angle(x, y, z : in signed; signal xa, ya, za : out signed) is
        variable quad : unsigned(1 downto 0);
        variable zp : signed(z'length-1 downto 0) := z;
        variable yp : signed(y'length-1 downto 0) := y;
        variable xp : signed(x'length-1 downto 0) := x;
    begin

        -- 0-based quadrant number of angle
        quad := unsigned(zp(zp'high downto zp'high-1));

        if quad = 1 or quad = 2 then -- Rotate into quadrant 0 and 3 (right half of plane)
            xp := -xp;
            yp := -yp;
            -- Add 180 degrees (flip the sign bit)
            zp := (not zp(zp'left)) & zp(zp'left-1 downto 0);
        end if;

        xa <= xp;
        ya <= yp;
        za <= zp;
    end procedure;

begin
    adj: process(Clock, Reset) is
        constant Y : signed(Angle'range) := (others => '0');
        constant X : signed(Angle'range) := --to_signed(1, Angle'length);
        to_signed(integer(MAGNITUDE/cordic_gain(ITERATIONS) * 2.0 ** FRAC_BITS), Angle'length);
    begin

        -- 
        if Reset = RESET_ACTIVE_LEVEL then
            xa <= (others => '0');
            ya <= (others => '0');
            za <= (others => '0');
        elsif rising_edge(Clock) then
            adjust_angle(X, Y, Angle, xa, ya, za);
        end if;
    end process;

    c: cordic_pipelined
        generic map (
            SIZE => SIZE,
            ITERATIONS => ITERATIONS,
            RESET_ACTIVE_LEVEL => RESET_ACTIVE_LEVEL
        ) port map (
            Clock => Clock,
            Reset => Reset,

            X => xa,
            Y => ya,
            Z => za,

            X_result => Cos,
            Y_result => Sin,
            Z_result => open
        );

end Behavioral;
