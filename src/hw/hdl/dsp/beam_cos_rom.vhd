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


entity beam_cos_rom is
    port ( clk      : in std_logic;
           rst      : in std_logic;
           tbt_trig : in std_logic;
           dout     : out signed(15 downto 0)
         );
end beam_cos_rom;

architecture behv of beam_cos_rom is

    type rom_type is array(0 to 61) of signed(15 downto 0);
    signal addr : integer range 0 to 63;
    signal dout_i : signed(15 downto 0);
    
    --cosine lookup table
    signal ROM : rom_type := (x"7fff", x"f984", x"80a9", x"1362", x"7d60", x"dfeb", x"85e0", x"2c74", 
                              x"759f", x"c7a2", x"9016", x"43b5", x"690e", x"b1a7", x"9ee2", x"582f", 
                              x"582f", x"9ee2", x"b1a7", x"690e", x"43b5", x"9016", x"c7a2", x"759f", 
                              x"2c74", x"85e0", x"dfeb", x"7d60", x"1362", x"80a9", x"f984", x"7fff", 
                              x"f984", x"80a9", x"1362", x"7d60", x"dfeb", x"85e0", x"2c74", x"759f", 
                              x"c7a2", x"9016", x"43b5", x"690e", x"b1a7", x"9ee2", x"582f", x"582f", 
                              x"9ee2", x"b1a7", x"690e", x"43b5", x"9016", x"c7a2", x"759f", x"2c74", 
                              x"85e0", x"dfeb", x"7d60", x"1362", x"80a9", x"f984");
                              
 

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
