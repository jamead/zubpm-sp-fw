library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;


library work;
use work.bpm_package.ALL;  

 
entity spi_ad9510 is
  
  port (
    clk         : in  std_logic;                    
    reset 	    : in  std_logic; 
    reg_o       : in  t_reg_o_pll;              
    sclk        : out std_logic;                   
	sdo			: in std_logic;
    sdi 	    : out std_logic;
    csb         : out std_logic;
    func        : out std_logic
  );    

end spi_ad9510;

architecture rtl of spi_ad9510 is



  type     state_type is (IDLE, CLKP1, CLKP2);                   
  signal state          : state_type;
  signal sys_clk        : std_logic;                                                                        
  signal treg           : std_logic_vector(23 downto 0);  
                                                                   
  signal rreg           : std_logic_vector(7 downto 0);   
  signal rddata         : std_logic_vector(7 downto 0);   
  signal bcnt           : integer range 0 to 63;         
  signal xfer_done      : std_logic;                      
  signal rwn	        : std_logic;     

  signal clk_cnt        : std_logic_vector(7 downto 0);  
  signal clk_enb        : std_logic;
  signal strobe_cnt		: std_logic_vector(15 downto 0);  

  signal we_lat			:  std_logic;
  signal we_lat_clr		: std_logic;

  signal spi_data	    : std_logic_vector(23 downto 0);
  
  
  
--   attribute mark_debug     : string;
--   attribute mark_debug of reg_o: signal is "true";
--   attribute mark_debug of sclk: signal is "true";
--   attribute mark_debug of csb: signal is "true";   
--   attribute mark_debug of sdi: signal is "true";   
--   attribute mark_debug of we_lat: signal is "true";
  
  
begin  

func <= '1';


process (clk, reset)
 begin
    if (reset = '1') OR (we_lat_clr = '1') then
	  we_lat <= '0';
    elsif (clk'event and clk = '1') then
	  if (reg_o.str = '1') then
	    we_lat <= '1';
		spi_data <= reg_o.data(23 downto 0);
	  end if;
    end if;
end process;



  spiStateProc: process (clk, reset)
  begin  
    if (reset = '1') then            
      sclk <= '0';
      csb  <= '1';
	  sdi <= '0';
      treg <= (others => '0');
      rreg <= (others => '0');
      bcnt <= 24;
      xfer_done <= '0';
	  we_lat_clr <= '0';
      state <= IDLE;

    elsif (rising_edge(clk)) then  
      if (clk_enb = '1') then
        case state is
          when IDLE =>     
            sclk  <= '0';
            csb  <= '1';
            xfer_done <= '0';
            we_lat_clr <= '0';
            if (we_lat = '1') then
				we_lat_clr <= '1';
                treg <= spi_data;  
                bcnt <= 24;  -- 16-bit address and 8-bit data
                state <= CLKP1;
            end if;

          when CLKP1 =>                  
			sclk  <= '0';
            csb  <= '0';
            state <= CLKP2;
			treg <= treg(22 downto 0) & '0';
            sdi <= treg(23);

          when CLKP2 =>                  
            if (bcnt = 0) then
              csb <= '1';
              if (rwn = '1') then
			    rddata <= rreg;
			  else
			    rddata <= x"00";
			  end if;
			  xfer_done <= '1';
              we_lat_clr <= '1';				
              state <= IDLE;
            else
			  rreg <= rreg(6 downto 0) & sdo;
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
