library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bus_switch is
    generic (ADDR_WIDTH : integer :=12);
    Port ( reset : in std_logic;
           sw_en : in std_logic;

           ce_wr : in std_logic;
           oe_wr : in std_logic;
           we_wr : in std_logic;
           addr_wr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
           data_wr : in std_logic_vector(7 downto 0);

           ce_rd : in std_logic;
           oe_rd : in std_logic;
           we_rd : in std_logic;
           addr_rd : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
           data_rd : out std_logic_vector(7 downto 0);

           ce_r1 : out std_logic;
           oe_r1 : out std_logic;
           we_r1 : out std_logic;
           addr_r1 : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
           data_r1 : inout std_logic_vector(7 downto 0);
		 
           ce_r2 : out std_logic;
           oe_r2 : out std_logic;
           we_r2 : out std_logic;
           addr_r2 : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
           data_r2 : inout std_logic_vector(7 downto 0));
end bus_switch;

architecture DASS of bus_switch is
   constant RESET_ACTIVE : std_logic := '0';
   signal s_c : std_logic;
begin
   process(sw_en,reset)
   begin
      if reset = RESET_ACTIVE then
	    s_c <= '0';
      elsif sw_en'event and sw_en = '1' then
	    s_c <= not s_c;
      end if;
   end process;

   process(s_c,ce_wr, oe_wr, we_wr, addr_wr, data_wr, ce_rd, oe_rd, we_rd, addr_rd)
   begin
      if s_c = '0' then
	    ce_r1 <= ce_wr;
	    oe_r1 <= oe_wr;
	    we_r1 <= we_wr;
	    addr_r1 <= addr_wr;
	    data_r1 <= data_wr;

	    ce_r2 <= ce_rd;
	    oe_r2 <= oe_rd;
	    we_r2 <= we_rd;
	    addr_r2 <= addr_rd;
	    data_r2 <= (others => 'Z');
	    data_rd <= data_r2;
      else
	    ce_r2 <= ce_wr;
	    oe_r2 <= oe_wr;
	    we_r2 <= we_wr;
	    addr_r2 <= addr_wr;
	    data_r2 <= data_wr;

	    ce_r1 <= ce_rd;
	    oe_r1 <= oe_rd;
	    we_r1 <= we_rd;
	    addr_r1 <= addr_rd;
	    data_r1 <= (others => 'Z');
	    data_rd <= data_r1;
	 end if;
   end process;
end DASS;
