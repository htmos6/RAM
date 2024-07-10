library ieee;
use ieee.std_logic_1164.all;


package ram_pkg is
    function log2 (depth: in natural) return integer;
end ram_pkg;


package body ram_pkg is
	function log2( depth : natural) return integer is
		
		variable temp    : integer := depth;
		variable ret_val : integer := 0;
		
		begin
			while temp > 1 loop
				ret_val := ret_val + 1;
				temp    := temp / 2;
			end loop;
		return ret_val;
			
	end function;
end package body;


library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;
use std.textio.all;


entity xilinx_single_port_ram_read_first is
	generic 
	(
		RAM_WIDTH : integer := 16; -- Specify RAM data width
		RAM_DEPTH : integer := 128; -- Specify RAM depth (number of entries) - 7bit addresses
		RAM_PERFORMANCE : string := "LOW_LATENCY"; -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
		INIT_FILE : string := "RAM_INIT.dat" -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );
	port 
	(
        address_i : in std_logic_vector((log2(RAM_DEPTH)-1) downto 0); -- Address bus, width determined from RAM_DEPTH
        ram_input_data_i  : in std_logic_vector(RAM_WIDTH-1 downto 0); -- RAM input data
        clk_i  : in std_logic; -- Clock
        write_enable_i   : in std_logic; -- Write enable
        ram_output_data_o : out std_logic_vector(RAM_WIDTH-1 downto 0) -- RAM output data
    );
end entity;



architecture rtl of xilinx_single_port_ram_read_first is

	constant C_RAM_WIDTH : integer := RAM_WIDTH;
	constant C_RAM_DEPTH : integer := RAM_DEPTH;
	constant C_RAM_PERFORMANCE : string := RAM_PERFORMANCE;

	-- Firstly, define the number of rows.
	-- Secondly, define the type of the each row.
	--
	-- type ARR_2D is array (15 downto 0) of std_logic_vector(3 downto 0);
	--
	-- ARR_2D is the type of the 2D array, consisting of 16 rows (15 downto 0), each of which is an std_logic_vector of 4 bits (3 downto 0).
	--
	type T_RAM is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_RAM_WIDTH-1 downto 0); -- 2D Array Declaration for RAM signal
	signal ram_data : std_logic_vector(C_RAM_WIDTH-1 downto 0) ; -- RAM data which is stored in a single row.

	signal ram_output_data_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');


	-- Following code defines RAM
	signal BRAM_virtual : T_RAM := (others => (others => '0'));
	
	attribute ram_style : string;
	attribute ram_style of BRAM_virtual : signal is "block";
	

begin


	process(clk_i) begin
		if(rising_edge(clk_i)) then
		
			if(write_enable_i = '1') then
				BRAM_virtual(to_integer(unsigned(address_i))) <= ram_input_data_i;
			end if;
			
			ram_data <= BRAM_virtual(to_integer(unsigned(address_i)));
			
		end if;
	end process;


	--  Following code generates LOW_LATENCY (no output register)
	--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
	no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
		ram_output_data_o <= ram_data;
	end generate;


	--  Following code generates HIGH_PERFORMANCE (use output register)
	--  Following is a 2 clock cycle read latency with improved clock-to-out timing
	output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE"  generate
		process(clk_i) begin
			if(rising_edge(clk_i)) then
				
				ram_output_data_reg <= ram_data;
				
			end if;
		end process;
	
		ram_output_data_o <= ram_output_data_reg;
		
	end generate;


end architecture;

						
						