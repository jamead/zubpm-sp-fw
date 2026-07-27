----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/05/2019 09:26:06 AM
-- Design Name: 
-- Module Name: beam_sine_rom - Behavioral
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
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity beam_sine_rom is
    port ( clk      : in std_logic;
           rst      : in std_logic;
           tbt_trig : in std_logic;
           dout     : out signed(15 downto 0)
         );
end beam_sine_rom;

architecture behv of beam_sine_rom is

    type rom_type is array(0 to 61) of signed(15 downto 0);
    signal addr : integer range 0 to 63;
    signal dout_i : signed(15 downto 0);
    
    --cosine lookup table
    signal ROM : rom_type := (x"0000", x"7fd5", x"f30d", x"817b", x"19c4", x"7be9", x"d9af", x"87f9", 
                              x"327a", x"72ea", x"c1e2", x"9360", x"491f", x"6537", x"aca0", x"a33b", 
                              x"5cc5", x"5360", x"9ac9", x"b6e1", x"6ca0", x"3e1e", x"8d16", x"cd86", 
                              x"7807", x"2651", x"8417", x"e63c", x"7e85", x"0cf3", x"802b", x"0000", 
                              x"7fd5", x"f30d", x"817b", x"19c4", x"7be9", x"d9af", x"87f9", x"327a", 
                              x"72ea", x"c1e2", x"9360", x"491f", x"6537", x"aca0", x"a33b", x"5cc5", 
                              x"5360", x"9ac9", x"b6e1", x"6ca0", x"3e1e", x"8d16", x"cd86", x"7807", 
                              x"2651", x"8417", x"e63c", x"7e85", x"0cf3", x"802b");
                              
 

begin


addr_gen: process(clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1' or tbt_trig = '1') then
        addr <= 0;
      else
        addr <= addr + 1;
        if (addr = 61) then
          addr <= 0;
        end if;
      end if;
    end if;
end process;


rom_lkup: process(clk, rst)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        dout_i <= x"0000";
      else
        dout_i <= ROM(addr);
      end if;
    end if;
 end process;


--register the output
process(clk, rst)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then 
         dout <= x"0000";
      else
         dout <= dout_i;
      end if;
    end if;
 end process;



end behv;

