library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.bpm_package.ALL;  


entity spi_pe43712 is
  
  port (
    clk         : in  std_logic;                       
    reset       : in  std_logic; 
    reg_o       : in  t_reg_o_dsa; 
    sclk        : out std_logic;                       
    sdi 	    : out std_logic;
    csb         : out std_logic                           
  );    

end spi_pe43712;
 
architecture rtl of spi_pe43712 is

  type   state_type is (IDLE, CLKP1, CLKP2);                    
  signal state             : state_type;
                                                                              
  signal treg              : std_logic_vector(15 downto 0);  
  signal bcnt          		: integer range 0 to 31;          
  signal xfer_active 		: std_logic;                      

  signal clk_enb           : std_logic;  
  signal clk_cnt           : std_logic_vector(7 downto 0);  
  
  signal str_lat            : std_logic;
  signal str_lat_clr        : std_logic;
  signal spi_data           : std_logic_vector(7 downto 0); 


--  attribute mark_debug     : string;
--  attribute mark_debug of reg_o: signal is "true";
--  attribute mark_debug of sclk: signal is "true";
--  attribute mark_debug of sdi: signal is "true";  
--  attribute mark_debug of csb: signal is "true";
--  attribute mark_debug of state: signal is "true";
--  attribute mark_debug of str_lat: signal is "true";
--  attribute mark_debug of str_lat_clr: signal is "true";   
 
  
  
begin  


--latch the strobe signal from the processor
process (clk, reset)
 begin
    if (reset = '1') OR (str_lat_clr = '1') then
	  str_lat <= '0';
    elsif (rising_edge(clk)) then
	  if (reg_o.str = '1') then
	    str_lat <= '1';
		spi_data <= reg_o.data(7 downto 0);
	  end if;
    end if;
end process;




-- generate SPI signals 
process (clk, reset)
  begin  
    if (reset = '1') then               
      sclk  <= '0';
      csb  <= '0';
	  sdi <= '0';
	  str_lat_clr <= '0';
      treg <= (others => '0');
      bcnt <= 0;
      xfer_active <= '0';
      state <= IDLE;

    elsif (rising_edge(clk)) then 
      if (clk_enb = '1') then
        case state is
          when IDLE =>     
            sclk  <= '0';
            csb  <= '0';
			sdi  <= '0';
            xfer_active <= '0';
            str_lat_clr <= '0';
            if (str_lat = '1') then
                xfer_active <= '1';
				str_lat_clr <= '1';
                treg <= x"00" & spi_data; --reg_o.data; 
                bcnt <= 16;  -- 8-bit address and 8-bit data
                state <= CLKP1;
            end if;

          when CLKP1 =>                  
            sclk  <= '0';
            csb  <= '0';
            state <= CLKP2;
			treg <= '0' & treg(15 downto 1);
            sdi <= treg(0);

          when CLKP2 =>                  
            if (bcnt = 0) then
              csb <= '1';
			  xfer_active <= '0';
              state <= IDLE;
            else
              sclk <= '1';
              bcnt <= bcnt - 1;
              state <= CLKP1;
			end if;
 
    
          when others =>
            state <= IDLE;
        end case;
      end if;
    end if;
end process;





clkdivide : process(clk, reset)
  begin
     if (rising_edge(clk)) then
       if (reset = '1') then  
          clk_cnt <= (others => '0');
          clk_enb <= '0';
       else
          clk_cnt <= clk_cnt + 1;
          if (clk_cnt = 8d"32") then  
             clk_cnt <= 8d"0";
		 	 clk_enb <= '1';
		  else 	 
		 	 clk_enb <= '0'; 
		  end if;
	   end if;
    end if;
end process; 






  
end rtl;
