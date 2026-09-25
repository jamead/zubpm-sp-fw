-- Measures the number of ADC clock cycles from a trigger until beam is detected.
-- Beam is considered present when the absolute value of any of the four ADC
-- channels exceeds the programmed threshold.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.bpm_package.ALL;

entity beam_detect is
  port (
    adc_clk     : in  std_logic;
    adc_rst     : in  std_logic;
    trigger     : in  std_logic;
    adc_data    : in  t_adc_raw;
    threshold   : in  std_logic_vector(15 downto 0);
    clock_count : out std_logic_vector(31 downto 0);
    done        : out std_logic
  );
end entity beam_detect;

architecture behv of beam_detect is

  signal trig_sync     : std_logic_vector(1 downto 0) := (others => '0');
  signal trig_sync_d   : std_logic := '0';
  signal threshold_hit : std_logic := '0';
  signal counting      : std_logic := '0';
  signal count_reg     : unsigned(31 downto 0) := (others => '0');

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of trig_sync : signal is "TRUE";
  
  attribute mark_debug     : string;
  attribute mark_debug of adc_data: signal is "true";  
  attribute mark_debug of trig_sync: signal is "true";  
  attribute mark_debug of trig_sync_d: signal is "true";  
  attribute mark_debug of threshold: signal is "true";  
  attribute mark_debug of clock_count: signal is "true";  
  attribute mark_debug of done: signal is "true";  
  attribute mark_debug of counting: signal is "true";  
  attribute mark_debug of threshold_hit: signal is "true";  
  attribute mark_debug of count_reg: signal is "true";  



  

begin

  threshold_hit <= '1' when
    (abs(resize(signed(adc_data(0)), 17)) > signed('0' & threshold)) or
    (abs(resize(signed(adc_data(1)), 17)) > signed('0' & threshold)) or
    (abs(resize(signed(adc_data(2)), 17)) > signed('0' & threshold)) or
    (abs(resize(signed(adc_data(3)), 17)) > signed('0' & threshold))
    else '0';

  process(adc_clk)
  begin
    if rising_edge(adc_clk) then
      if adc_rst = '1' then
        trig_sync   <= (others => '0');
        trig_sync_d <= '0';
      else
        trig_sync(0) <= trigger;
        trig_sync(1) <= trig_sync(0);
        trig_sync_d  <= trig_sync(1);
      end if;
    end if;
  end process;

  process(adc_clk)
  begin
    if rising_edge(adc_clk) then
      if adc_rst = '1' then
        count_reg <= (others => '0');
        clock_count <= (others => '0');
        counting  <= '0';
        done      <= '0';
      else
        done <= '0';

        if (trig_sync(1) = '1') and (trig_sync_d = '0') then
          count_reg <= (others => '0');
 
          if threshold_hit = '1' then
            counting <= '0';
            done     <= '1';
            clock_count <= (others => '0');   
          else
            counting <= '1';
          end if;

        elsif counting = '1' then
          if threshold_hit = '1' then
            counting <= '0';
            done     <= '1';
            clock_count <= std_logic_vector(count_reg);
          else
            count_reg <= count_reg + 1;
          end if;
        end if;
      end if;
    end if;
  end process;


end architecture behv;
