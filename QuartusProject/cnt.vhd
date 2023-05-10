library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cnt is
    generic (CNT_WIDTH : integer :=4);
    Port ( clr : in std_logic;	 --active high
           clk : in std_logic;
           en : in std_logic;
           q : out std_logic_vector(CNT_WIDTH-1 downto 0));
end cnt;

architecture DASS of cnt is
   signal s_q : std_logic_vector(CNT_WIDTH-1 downto 0);
begin
   process(clr,clk)
   begin
      if clr = '1' then
         s_q <= (others => '0');
      elsif clk'event and clk = '1' then
         if en = '1' then
	       s_q <= s_q + 1;
         end if;
      end if;
   end process;

   q <= s_q;
end DASS;
