library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;


library work;
use work.bpm_package.ALL;  

entity ltc2986_spi is
  port (
   clk             : in  std_logic;                    
   reset  	       : in  std_logic;    
   reg_o           : in  t_reg_o_therm;
   reg_i           : out t_reg_i_therm;   
   csn             : out std_logic_vector(2 downto 0);
   sck             : out std_logic;                   
   sdi 	           : out std_logic;
   sdo             : in std_logic;
   rstn            : out std_logic           
  );    
end ltc2986_spi;


architecture rtl of ltc2986_spi is

  type     state_type is (IDLE, CLKP1, CLKP2, DONE); 
  signal  state             : state_type;
  signal  sys_clk           : std_logic;                                                                              
  signal  treg              : std_logic_vector(31 downto 0);                                                                                                                                    
  signal  bcnt              : integer range 0 to 32;          
  signal  xfer_done         : std_logic;                      
   
  signal clk_cnt            : std_logic_vector(7 downto 0);  
 
  signal we_lat				: std_logic;
  signal we_lat_clr			: std_logic;
  
  signal spi_data			: std_logic_vector(31 downto 0);
  
  signal csn_i              : std_logic;

  
    --debug signals (connect to ila)
    attribute mark_debug                 : string;
    attribute mark_debug of sys_clk: signal is "true";   
    attribute mark_debug of state: signal is "true";
    attribute mark_debug of sck: signal is "true";
    attribute mark_debug of sdi: signal is "true";
    attribute mark_debug of sdo: signal is "true";    
    attribute mark_debug of csn_i: signal is "true";
    attribute mark_debug of csn: signal is "true";
    attribute mark_debug of we_lat: signal is "true";
    attribute mark_debug of reg_o: signal is "true";  
    attribute mark_debug of reg_i: signal is "true";  
  
  
begin  

rstn <= '1';

csn(2) <= csn_i when reg_o.sel = "10" else '1';
csn(1) <= csn_i when reg_o.sel = "01" else '1';
csn(0) <= csn_i when reg_o.sel = "00" else '1';


-- initiate spi command on we input
process (clk, reset)
   begin
     if (reset = '1') or (we_lat_clr = '1')  then
	     spi_data <= (others => '0');
	     we_lat <= '0';
     elsif (clk'event and clk = '1') then
		   if (reg_o.spi_we = '1') then
	           we_lat <= '1';
			   spi_data <= reg_o.spi_wdata(31 downto 0);
	    	end if;
     end if;
end process;


-- spi transfer
process (sys_clk, reset)
  begin  -- process spiStateProc
    if (reset = '1') then  
      csn_i <= '1';      
      sck <= '0';
	  sdi <= '0';
	  reg_i.spi_rdata <= x"00";
      treg <= (others => '0');
      bcnt <= 32;
      xfer_done <= '0';
	  we_lat_clr <= '0';
      state <= IDLE;

    elsif (sys_clk'event and sys_clk = '1') then  
      case state is
        when IDLE =>    
           csn_i  <= '1'; 
           sck  <= '0';
           sdi  <= '0';
           xfer_done <= '0';
           bcnt <= 31;
           we_lat_clr <= '0';
           if (we_lat = '1') then
                csn_i <= '0';
                treg <= spi_data;   
                bcnt <= 31;
                state <= CLKP1;
           end if;          

        when CLKP1 =>     -- CLKP1 clock phase LOW
			sck  <= '0';
            state <= CLKP2;
			treg <= treg(30 downto 0) & '0';
            sdi <= treg(31);

        when CLKP2 =>     -- CLKP1 clock phase 2
           sck <= '1';
           if (bcnt <= 7) then
              reg_i.spi_rdata(bcnt) <= sdo;
           end if;
           if (bcnt = 0) then
			   xfer_done <= '1';
               we_lat_clr <= '1';				
               state <= done;
           else
               bcnt <= bcnt - 1;
               state <= CLKP1;
		   end if;

        when DONE =>
           sck <= '0';
           sdi <= '0';
           state <= idle;
        when others =>
            state <= IDLE;
      end case;
    end if;
  end process;





--generate sys clk (1.2MHz) for spi from 100Mhz clock
sysclk_bufg_inst : BUFG  port map (O => sys_clk, I => clk_cnt(6));

clkdivide : process(clk, reset)
  begin
     if (reset = '1') then  
       clk_cnt <= (others => '0');
    elsif (clk'event AND clk = '1') then  
		 	 clk_cnt <= clk_cnt + 1; 
    end if;
end process; 




  
end rtl;
