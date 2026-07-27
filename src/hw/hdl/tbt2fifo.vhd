-------------------------------------------------------------------------------
-- Title         : TbT FIFO
-------------------------------------------------------------------------------
-- File          : tbt2fifo.vhd
-- Author        : Joseph Mead  mead@bnl.gov
-- Created       : 01/11/2013
-------------------------------------------------------------------------------
-- Description:
-- Provides logic to send tbt data to FIFO interface.
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
  
entity tbt2fifo is
  port (
    sys_clk          	: in  std_logic;
    adc_clk             : in  std_logic;
    reset     			: in  std_logic; 
    reg_o               : in  t_reg_o_tbt_fifo_rdout;
	reg_i               : out t_reg_i_tbt_fifo_rdout;                       	
	tbt_data            : in t_tbt_data;
	tbt_trig            : in std_logic
);    
end tbt2fifo;

architecture behv of tbt2fifo is
  

component tbtbuf_fifo IS
  port (
    wr_clk : IN STD_LOGIC;
    wr_rst : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    rd_rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    rd_data_count : OUT STD_LOGIC_VECTOR(14 DOWNTO 0)
  );
end component;


  
  type     state_type is (IDLE, ARM, WR_V0, WR_V1, WAITFORTBTTRIG);                   
  signal   state   : state_type;  
 
  
  signal fifo_din          : std_logic_vector(31 downto 0);
  signal fifo_full         : std_logic;
  signal fifo_empty        : std_logic;
  signal fifo_rd_data_cnt  : std_logic_vector(14 downto 0);
  signal fifo_wren         : std_logic;
  signal fifo_rdstr_prev   : std_logic;
  signal fifo_rdstr_fe     : std_logic;
  signal tbt_stream_enb_sr : std_logic_vector(2 downto 0);
  signal tbt_stream_enb_s  : std_logic;
  signal sample_num        : std_logic_vector(31 downto 0);
  
  
  
--  attribute mark_debug              : string;
--  attribute mark_debug of reg_o: signal is "true";
--  attribute mark_debug of reg_i: signal is "true";
--  attribute mark_debug of tbt_trig: signal is "true";
--  attribute mark_debug of tbt_data: signal is "true";
--  attribute mark_debug of state: signal is "true";
--  attribute mark_debug of fifo_din: signal is "true";
--  attribute mark_debug of fifo_wren: signal is "true";

--  attribute mark_debug of tbt_stream_enb_sr: signal is "true";
--  attribute mark_debug of tbt_stream_enb_s: signal is "true";

--  attribute mark_debug of fifo_rdstr_fe: signal is "true";
--  attribute mark_debug of fifo_rd_data_cnt: signal is "true";


begin  



reg_i.rdcnt  <= 17d"0" & fifo_rd_data_cnt;


--since fifo is fall-through mode, want the rdstr
--to happen after the current word is read.
process (reset,sys_clk)
   begin
       if (reset = '1') then
          fifo_rdstr_prev <= '0';
          fifo_rdstr_fe <= '0';
       elsif (sys_clk'event and sys_clk = '1') then
          fifo_rdstr_prev <= reg_o.rdstr;
          if (reg_o.rdstr = '0' and fifo_rdstr_prev = '1') then
              fifo_rdstr_fe <= '1'; --falling edge
          else
              fifo_rdstr_fe <= '0';
          end if;
       end if;
end process;




-- sync tbt_stream_enb to adc clock domain
process (adc_clk)
begin
  if (rising_edge(adc_clk)) then
	if (reset = '1') then
	  tbt_stream_enb_sr <= "000";
    else
      tbt_stream_enb_sr(0) <= reg_o.enb;
      tbt_stream_enb_sr(1) <= tbt_stream_enb_sr(0);
      tbt_stream_enb_sr(2) <= tbt_stream_enb_sr(1);
    end if;
    if (tbt_stream_enb_sr(2) = '0' and tbt_stream_enb_sr(1) = '1') then
      tbt_stream_enb_s <= '1';
    else
      tbt_stream_enb_s <= '0';
    end if;
  end if;
end process;








tbtfifo : tbtbuf_fifo
  PORT MAP (
    wr_clk          => adc_clk,
    wr_rst          => reg_o.rst,
    wr_en           => fifo_wren,  
    din             => fifo_din,    
    rd_clk          => sys_clk,
    rd_rst          => reg_o.rst,
    rd_en           => fifo_rdstr_fe,
    dout            => reg_i.dout,
    full            => fifo_full,
    empty           => fifo_empty,
    rd_data_count   => fifo_rd_data_cnt
  );




--write samples to fifo
process(adc_clk)
  begin
     if (rising_edge(adc_clk)) then
       if (reset = '1') then
          fifo_wren <= '0';
          sample_num <= (others => '0');
          state <= idle;
          fifo_din <= (others => '0');
       else
         case state is
           when IDLE =>  
             fifo_wren <= '0'; 
             sample_num <= (others => '0');    
             if (tbt_stream_enb_s = '1') then
                state <= arm;
             end if;
             
           when ARM =>  
             if (tbt_trig = '1') then
                state <= wr_v0;
             end if;
           
           when WR_V0 => 
              fifo_wren <= '1';
              fifo_din <= std_logic_vector(tbt_data.xpos_nm);
              state <= wr_v1;             
                                   
           when WR_V1 =>
              fifo_din <= std_logic_vector(tbt_data.ypos_nm);
              sample_num <= sample_num + 1;
              state <= waitfortbttrig;      
              
           when WAITFORTBTTRIG =>             
              fifo_din <= x"01234567"; --(others => '0');
              fifo_wren <= '0';  
              if (sample_num = 32d"8010") then
                 state <= idle;
              elsif (tbt_trig = '1') then
                 state <= wr_V0;
              end if;
              
          when OTHERS => 
              state <= idle;    
              
         end case;
       end if;
     end if;
end process; 



  
end behv;