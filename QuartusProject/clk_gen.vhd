library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_gen is
    Port ( reset : in std_logic;
           clk : in std_logic;
           sck : out std_logic;    -- AD system clock 
           bck : out std_logic;    -- AD bit clock
           lrck : out std_logic;   -- AD sample clock
           tick : out std_logic);	-- the position of 1/4 lrck,active high				 
end clk_gen;

architecture DASS of clk_gen is
---------------------------------------------------------------------------
   ------------------- Constants definition -------------------------
   constant RESET_ACTIVE : std_logic := '0';
   ---------- signal definition -------------------------------------
   signal s_cnt : std_logic_vector(8 downto 0);
---------------------------------------------------------------------------
begin
   ---------------------------------------------
   ----- process to generate the counter -------
   ---------------------------------------------
   process(clk, reset)
   begin
	 if reset=RESET_ACTIVE then
	    s_cnt <= (others => '0');
      elsif clk'event and clk='1' then
	    s_cnt <= s_cnt + 1;
      end if;
   end process;
   ----------------------------------------------
   ------ Output the clock signal ---------------
   ----------------------------------------------
   sck  <= clk;
   bck  <= s_cnt(3);
   lrck <= s_cnt(8);
   -----------------------------------------------------
   ------- the process to generate the tick signal -----
   -----------------------------------------------------
   process(reset,clk)
   begin
	 if reset=RESET_ACTIVE then
	    tick <= '0';
      elsif clk'event and clk='1' then
	    if s_cnt(7 downto 0) = "01111111" then
	       tick <= '1';
         else 
	       tick <= '0';
         end if;
      end if;      
   end process;
-----------------------------------------------------------
end DASS;
