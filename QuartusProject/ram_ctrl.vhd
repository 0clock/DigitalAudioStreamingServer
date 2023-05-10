library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ram_ctrl is
    generic (ADDR_WIDTH : integer :=12);
    Port ( reset : in std_logic;
           clk : in std_logic;
           ds : in std_logic;		-- high edge active
           lrc : in std_logic;
           hlb : in std_logic;
           data0 : in std_logic_vector(7 downto 0);
           data1 : in std_logic_vector(7 downto 0);
           full : out std_logic;
           ce : out std_logic;
		 oe : out std_logic;
           we : out std_logic;
           addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
           data : out std_logic_vector(7 downto 0));
end ram_ctrl;

architecture DASS of ram_ctrl is
--************************************************************************************
   --**************************** Constants *************************
   constant RESET_ACTIVE : std_logic := '0';
   constant ADDRCNT_WIDTH : integer := ADDR_WIDTH-3;
   --constant ADDRCNT_MAX : std_logic_vector(ADDRCNT_WIDTH-2 downto 0) := (others => '1');
   constant WCCNT_WIDTH : integer := 2;
   constant WCCNT_MAX : std_logic_vector(WCCNT_WIDTH-1 downto 0) := (others => '1');
   -------------------- type definition -----------------------------
   type t_writestate is(idle,write0,write1);
   --**********************signal definition*************************
   signal pre_state,next_state : t_writestate;
   signal s_hlb : std_logic;
   signal s_sel : std_logic_vector(1 downto 0);

   signal s_ce,s_we : std_logic;
   signal s_dataout : std_logic_vector(7 downto 0);

   signal s_ds : std_logic;

   signal s_addrcnt : std_logic_vector(ADDRCNT_WIDTH-1 downto 0);
   signal s_addrcnt_clr,s_addrcnt_en : std_logic;

   signal s_addr_h : std_logic; -- the delay version of the significant bit of addr
   
   signal s_wccnt : std_logic_vector(WCCNT_WIDTH-1 downto 0);
   signal s_wccnt_clr,s_wccnt_en : std_logic;

   signal s_full : std_logic;
   ----------component declaration-----------------------
   component cnt is
       generic (CNT_WIDTH : integer :=4);
       Port ( clr : in std_logic;  --active high
              clk : in std_logic;
              en : in std_logic;
              q : out std_logic_vector(CNT_WIDTH-1 downto 0));
   end component;
--***********************************************************************************
begin
----------------------------------------------------------------
   --------component instantiation------------------------------
   -------------------------------------------------------------
   addrcnt_inst : cnt 
    generic map (CNT_WIDTH => ADDRCNT_WIDTH)
    Port map ( clk =>clk,
               clr =>s_addrcnt_clr,	  --asynchronous clear,active high
               en =>s_addrcnt_en,
               q =>s_addrcnt);


   wccnt_inst : cnt 
    generic map (CNT_WIDTH => WCCNT_WIDTH)
    Port map ( clk =>clk,
               clr =>s_wccnt_clr, --asynchronous clear,active high
               en =>s_wccnt_en,
               q =>s_wccnt);
   -------------------------------------------------------------
   ----------------process to sample the signal ds--------------
   -------------------------------------------------------------
   process(reset,clk)
   begin
      if reset=RESET_ACTIVE then
	    s_ds<='0';
      elsif clk'event and clk='1' then
	    s_ds<=ds;
      end if;
   end process;
   -------------------------------------------------------------
   ---------------- The write ram control state machine --------
   -------------------------------------------------------------
   --- state register
   process(clk,reset)
   begin
      if reset = RESET_ACTIVE then
	    pre_state <= idle;
      elsif clk'event and clk = '1' then
	    pre_state <= next_state;
      end if;
   end process;
   --- next state logic
   process(pre_state,ds,s_ds,s_wccnt)
   begin
	 case pre_state is
	    when idle   =>
	                 if ds = '1' and s_ds = '0' then
				     next_state <= write0;
                      else
				     next_state <= idle;
				  end if;
         when write0 =>		             
		   	       if s_wccnt = WCCNT_MAX then
					next_state <= write1;
                      else
					next_state <= write0;
                      end if;
         when write1 =>
			       if s_wccnt = WCCNT_MAX then
					next_state <= idle;
                      else
					next_state <= write1;
                      end if;
         when others =>
		            next_state <= idle;   
	 end case;
   end process;
   -----------------------------------------------------------
   ---------------- counter control process ------------------
   -----------------------------------------------------------
   process(pre_state,s_wccnt,lrc,hlb)
   begin
      if (pre_state = write0 or pre_state = write1) then
	    s_wccnt_clr <= '0';
	    s_wccnt_en <= '1';
      else
	    s_wccnt_clr <= '1';
	    s_wccnt_en <= '0';
	 end if;

      if pre_state =write1 and s_wccnt = WCCNT_MAX and lrc = '1' and hlb = '0' then -- right channel,low byte, indicate one sample has finished
	    s_addrcnt_en <= '1';
      else
	    s_addrcnt_en <= '0';
      end if;	       
   end process;

   s_addrcnt_clr <= not reset;
   -----------------------------------------------------------
   ------------------ ram control signal ---------------------
   -----------------------------------------------------------
   process(pre_state,s_wccnt,data0,data1,hlb,lrc)
   --process(clk)
   begin
      --if clk'event and clk = '1' then
	 case pre_state is
	    when idle   =>
	                 s_ce <= '1';
	                 s_we <= '1';
	                 s_dataout <= (others => '0');
			       s_hlb <= '0';
	                 s_sel <= (others => '0');
	    when write0 =>
	                 s_ce <= '0';
	                 s_we <= s_wccnt(WCCNT_WIDTH-1);
	                 s_dataout <= data0;
	                 s_hlb <= hlb;
	                 s_sel <= '0' & lrc;   
	    when write1 =>
	                 s_ce <= '0';
	                 s_we <= s_wccnt(WCCNT_WIDTH-1);
	                 s_dataout <= data1;
	                 s_hlb <= hlb;
	                 s_sel <= '1' & lrc;
	    when others =>
	                 s_ce <= '1';
	                 s_we <= '1';
	                 s_dataout <= (others => '0');
	                 s_hlb <= '0';
	                 s_sel <= (others => '0');		  		        	      
      end case;
	 --end if;
   end process;
   -----------------------------------------------------------
   --------------  output the ram signal ---------------------
   -----------------------------------------------------------
   ce <= s_ce;
   oe <= '1';
   we <= s_we;
   data <= s_dataout;
   addr <= s_sel & s_addrcnt(ADDRCNT_WIDTH-1 downto 0) & s_hlb;
   -----------------------------------------------------------
   -------------- The full arbitrary process ------------------
   -----------------------------------------------------------
   process(reset,clk)
   begin
      if reset = RESET_ACTIVE then
	    s_addr_h <= '0';
	    s_full <= '0';
      elsif clk'event and clk = '1' then
	    s_addr_h <= s_addrcnt(ADDRCNT_WIDTH-1);
	    if s_addr_h = '1' and s_addrcnt(ADDRCNT_WIDTH-1) = '0' then
	       s_full <= '1';
         else
	       s_full <= '0';
         end if;
      end if;
   end process;
   full <= s_full;
   -----------------------------------------------------------
end DASS;
