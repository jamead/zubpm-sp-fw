-------------------------------------------------------------------------------
-- Title         : AXI Data Generator
-------------------------------------------------------------------------------
-- File          : axi_data_gen.vhd
-- Author        : Joseph Mead  mead@bnl.gov
-- Created       : 01/11/2013
-------------------------------------------------------------------------------
-- Description:
-- Provides logic to send adc or test data to FIFO interface.
-- A testdata_en input permits test counters to be sent for verification 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Modification history:
-- 01/11/2013: created.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;
  
library work;
use work.bpm_package.ALL;  
  
entity tbt2dma is
  port (
    sys_clk          	: in  std_logic;
    adc_clk             : in  std_logic;
    reset     			: in  std_logic;                       
    trig		 		: in  std_logic;
    reg_o               : in t_reg_o_dma; 	
	tbt_data            : in t_tbt_data;
	tbt_trig            : in std_logic;
	dma_active          : out std_logic;
	  
    m_axis_tdata        : out std_logic_vector(63 downto 0);
    m_axis_tkeep        : out std_logic_vector(7 downto 0);
    m_axis_tlast        : out std_logic;
    m_axis_tready       : in std_logic;
    m_axis_tvalid       : out std_logic     
  );    
end tbt2dma;

architecture rtl of tbt2dma is
  

component adcdata_fifo
  PORT (
    s_axis_aresetn : IN STD_LOGIC;
    s_axis_aclk : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    s_axis_tlast : IN STD_LOGIC;
    m_axis_aclk : IN STD_LOGIC;
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_tlast : OUT STD_LOGIC;
    axis_wr_data_count : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    axis_rd_data_count : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end component;


  
  type     state_type is (IDLE, ACTIVE, FIFO_WRITE_W0, FIFO_WRITE_W1, FIFO_WRITE_W2, FIFO_WRITE_W3,
                          FIFO_WRITE_W4, FIFO_WRITE_W5, FIFO_WRITE_W6, FIFO_WRITE_W7);                    
  signal   state   : state_type;  
  

  signal len			   : std_logic_vector(31 downto 0);
  signal testdata		   : std_logic_vector(63 downto 0); 
  
  signal fifo_wrlen        : std_logic_vector(31 downto 0); 
  
  signal data_wren_i	   : std_logic;   

  signal strobe_lat		   : std_logic;
  signal tx_active		   : std_logic;
  signal dlycnt            : INTEGER;
  
  signal trig_s            : std_logic_vector(2 downto 0);
  signal trig_fifo         : std_logic;
  
  signal tbt_tx_cnt        : INTEGER;
  
  
  signal fifo_din          : std_logic_vector(127 downto 0);
  signal fifo_full         : std_logic;
  signal fifo_rdcnt        : std_logic_vector(31 downto 0);
  signal fifo_wrcnt        : std_logic_vector(31 downto 0);
 
  signal fifo_rden         : std_logic;
  signal fifo_wren         : std_logic;
  signal fifo_testdata     : std_logic_vector(63 downto 0);
  
  signal s_axis_aresetn   : std_logic;
  signal s_axis_tready    : std_logic;
  signal s_axis_tdata     : std_logic_vector(63 downto 0);
  signal s_axis_tbtdata   : std_logic_vector(63 downto 0);
  signal s_axis_testdata  : std_logic_vector(63 downto 0);
  signal s_axis_tvalid    : std_logic;
  signal s_axis_tlast     : std_logic;
  
  signal burst_len        : std_logic_vector(31 downto 0);

  
  
--  attribute mark_debug              : string;
----  attribute mark_debug of trig : signal is "true";
----  attribute mark_debug of tx_active : signal is "true";
----  attribute mark_debug of strobe_lat : signal is "true";
----  attribute mark_debug of testdata : signal is "true";
--  attribute mark_debug of tbt_trig: signal is "true";
--  attribute mark_debug of burst_len : signal is "true";
----  attribute mark_debug of len : signal is "true";
--  attribute mark_debug of state: signal is "true";
--  attribute mark_debug of trig: signal is "true";
--  attribute mark_debug of trig_s: signal is "true";
--  attribute mark_debug of trig_fifo: signal is "true";
--  attribute mark_debug of fifo_wrcnt: signal is "true";
--  attribute mark_debug of fifo_rdcnt: signal is "true";
--  attribute mark_debug of fifo_wrlen: signal is "true";
--  --attribute mark_debug of s_axis_tdata: signal is "true";
--  attribute mark_debug of s_axis_testdata: signal is "true";
--  attribute mark_debug of s_axis_tbtdata: signal is "true";
--  attribute mark_debug of s_axis_tvalid: signal is "true";
--  attribute mark_debug of s_axis_tlast: signal is "true";
--  attribute mark_debug of s_axis_tready: signal is "true";  
--  attribute mark_debug of s_axis_aresetn: signal is "true";   
  
--  attribute mark_debug of m_axis_tdata: signal is "true";
--  attribute mark_debug of m_axis_tkeep: signal is "true";
--  attribute mark_debug of m_axis_tvalid: signal is "true";
--  attribute mark_debug of m_axis_tlast: signal is "true";
--  attribute mark_debug of m_axis_tready: signal is "true";   
 


begin  


m_axis_tkeep <= x"FF";
s_axis_aresetn <= not reg_o.fifo_rst; 


-- flip longword positions, maps big-endian
s_axis_tdata <= s_axis_tbtdata(31 downto 0) & s_axis_tbtdata(63 downto 32) when (reg_o.testdata_enb = '0') else 
                s_axis_testdata(31 downto 0) & s_axis_testdata(63 downto 32);

burst_len <= reg_o.tbt_len;

dma_active <= '0' when (fifo_wrlen = 32d"0") else '1';


u1fifo: adcdata_fifo
  port map (
    s_axis_aresetn => s_axis_aresetn, 
    s_axis_aclk => adc_clk, 
    s_axis_tvalid => s_axis_tvalid, 
    s_axis_tready => s_axis_tready, 
    s_axis_tdata => s_axis_tdata, 
    s_axis_tlast => s_axis_tlast, 
    m_axis_aclk => sys_clk, 
    m_axis_tvalid => m_axis_tvalid, 
    m_axis_tready => m_axis_tready, 
    m_axis_tdata => m_axis_tdata, 
    m_axis_tlast => m_axis_tlast, 
    axis_wr_data_count => fifo_wrcnt, 
    axis_rd_data_count => fifo_rdcnt
  );






--keep fifo wren high for burstlen clocks
process (adc_clk)
begin 
  if (rising_edge(adc_clk)) then
    if (reset = '1') then
      s_axis_tlast <= '0';
      s_axis_tvalid <= '0';
      fifo_wrlen <= 32d"0";
      tbt_tx_cnt <= 0;
      s_axis_testdata <= (others => '0');
      s_axis_tbtdata <= (others => '0');
      state <= IDLE;
                
    else
      case state is 
        when IDLE =>
          s_axis_tlast <= '0';
          s_axis_tvalid <= '0';
          tbt_tx_cnt <= 0;
          if (trig = '1')  then
            state <= active;
            fifo_wrlen <= burst_len;
            fifo_testdata <= (others => '0');
          end if;
          
        when ACTIVE =>
           s_axis_tlast <= '0';
           s_axis_tvalid <= '0';
           if (tbt_trig = '1') then
             state <= fifo_write_w0;
             fifo_wrlen <= fifo_wrlen - 1;
           end if;

  
       when FIFO_WRITE_W0 =>
           s_axis_tvalid <= '1';
           s_axis_tbtdata <=  x"80000000" & std_logic_vector(to_unsigned(tbt_tx_cnt,32));
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w1;           
           
        when FIFO_WRITE_W1 =>
           s_axis_tvalid <= '1';
           s_axis_tbtdata <=  std_logic_vector(tbt_data.cha_mag) & std_logic_vector(tbt_data.cha_phs);
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w2;

        when FIFO_WRITE_W2 =>
           s_axis_tbtdata <=  std_logic_vector(tbt_data.chb_mag) & std_logic_vector(tbt_data.chb_phs);
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w3;   
            
        when FIFO_WRITE_W3 =>
           s_axis_tvalid <= '1';
           s_axis_tbtdata <=  std_logic_vector(tbt_data.chc_mag) & std_logic_vector(tbt_data.chc_phs);
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w4;

        when FIFO_WRITE_W4 =>
           s_axis_tbtdata <=  std_logic_vector(tbt_data.chd_mag) & std_logic_vector(tbt_data.chd_phs);
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w5;              
                     
        when FIFO_WRITE_W5 =>
           s_axis_tbtdata <=  std_logic_vector(tbt_data.xpos) & std_logic_vector(tbt_data.ypos);
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w6;
                          
        when FIFO_WRITE_W6 =>
           s_axis_tbtdata <=  x"00000000" & std_logic_vector(tbt_data.sum);
           s_axis_testdata <= s_axis_testdata + 1;
           state <= fifo_write_w7;   
           
        when FIFO_WRITE_W7 =>
           s_axis_tbtdata <=  std_logic_vector(tbt_data.xpos_nm) & std_logic_vector(tbt_data.ypos_nm);
           s_axis_testdata <= s_axis_testdata + 1;
           tbt_tx_cnt <= tbt_tx_cnt + 1;
           if (fifo_wrlen = 0) then
              s_axis_tlast <= '1';
              state <= idle;
           else
              state <= active;
           end if;
          
           
           
           
        when OTHERS =>
           state <= idle;
      end case;
    end if;
  end if;
end process;  







  
end rtl;
