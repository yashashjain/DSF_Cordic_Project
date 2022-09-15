library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_dac is
    generic (
        SIZE       : positive:=12       -- Width of parameters
    );
    port (
        clk_in : in std_logic;
        rst : in std_logic;
        datain : in unsigned (SIZE-1 downto 0);
        start : in std_logic;
        data   : out std_logic;
        cs   : out std_logic;
        sclk : out std_logic
    );
end spi_dac;

architecture Behavioral of spi_dac is
    signal count : integer range 0 to 33;
    signal data_in_reg : unsigned (SIZE-1 downto 0);
    type statetype is (s0, s1, s2);
    signal pr_state, nx_state: statetype;
    signal max , crst: std_logic;
begin

    conff: process (rst, clk_in)
    begin
        if (rst = '1') then
            pr_state <= s0;
        elsif (clk_in'event and clk_in = '1') then
            pr_state <= nx_state;
        end if;
    end process;

    conlog: process (pr_state, start, max)
    begin
        case pr_state is
            when s0 =>              -- Idle state
                crst <= '1';
                cs <= '1'; --DC
                if (start = '1') then
                    nx_state <= s1;
                else
                    nx_state <= s0;
                end if;

            when s1 =>             -- Register data
                crst <= '1';
                cs <= '1'; --DC
                data_in_reg <= datain;
                nx_state <= s2;

            when s2 =>
                crst <= '0';
                cs <= '0'; --DC
                if (max ='1') then
                    nx_state <= s0;
                else
                    nx_state <= s2;
                end if;

            when others =>
                crst <= '1';
                cs <= '1'; --DC
                nx_state <= s0;
        end case;
    end process;

    counter: process (clk_in)

    begin
        if (clk_in'event and clk_in = '1') then
            if (crst = '1') then
                count <= 0;
            else
                count <= count + 1;
                case  count is
                    when 0 => data <= '0'; --DC
                    when 1 => data <= '0'; --DC
                    when 2 => data <= '0';  -- 0 for Normal operation
                    when 3 => data <= '0'; -- 0 for Normal operation
                    when 4 => data <= datain(11); -- data[11]
                    when 5 => data <= datain(10);
                    when 6 => data <= datain(9);
                    when 7 => data <= datain(8);
                    when 8 => data <= datain(7);
                    when 9 => data <= datain(6);
                    when 10 => data <= datain(5);
                    when 11 => data <= datain(4);
                    when 12 => data <= datain(3);
                    when 13 => data <= datain(2);
                    when 14 => data <= datain(1);
                    when 15 => data <= datain(0);  --data[0]
                    when others => data <= '0';
                end case;
            end if;
        end if;
    end process;

    max <= '1' when (count = 16) else '0';
    sclk <= clk_in;

end Behavioral;


