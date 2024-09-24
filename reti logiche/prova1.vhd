----------------------------------------------------------------------------------
-- Company: 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    Port (
       i_clk : in std_logic;
       i_rst : in std_logic;
       i_start : in std_logic;
       i_data : in std_logic_vector(7 downto 0);
       o_address : out std_logic_vector(15 downto 0);
       o_done : out std_logic;
       o_en : out std_logic;
       o_we : out std_logic;
       o_data : out std_logic_vector (7 downto 0)
       );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
type state_type is(RESET,START,SET_ADDRESS,READ_COLUMN,READ_ROW,ROW_ADDRESS,
                   READ_PIXEL, DELTA_VALUE, SHIFT_LEVEL, READ_PIXEL_AGAIN,CALCULATE_NEW_VALUE,
                   WRITE_OUTPUT,RESET_ADDRESS,DONE);        
  signal CURRENT_STATE, NEXT_STATE : state_type;
  
  signal n_col: unsigned(7 downto 0):= "00000000";
  signal n_righe : unsigned(7 downto 0) := "00000000";
  signal currentPixel : unsigned(7 downto 0) := "00000000";
  signal newPixel : unsigned(7 downto 0) := "00000000";         
  signal maxPixelValue : unsigned(7 downto 0) := "00000000";    
  signal minPixelValue : unsigned(7 downto 0) := "11111111";     
  signal tempPixel : unsigned(7 downto 0) := "00000000";
  signal deltaValue : integer;
  signal shiftLevel : integer;
  signal n_pixel : unsigned(15 downto 0) := "0000000000000000";
  signal o_add : std_logic_vector(15 downto 0) := "0000000000000000";
  signal o_add_prec : std_logic_vector(15 downto 0) := "0000000000000000";
  signal contatore : unsigned(15 downto 0) := "0000000000000000";
  
begin
         FSA : process(i_clk)
	     begin
		    if(i_clk'event and i_clk='1') then
			   if(i_rst='1') then 
			        CURRENT_STATE <= RESET;
			   else 
			        CURRENT_STATE <= NEXT_STATE;
			   end if;
				   
			   case CURRENT_STATE is 
                  when RESET =>
                            n_col <= "00000000";
						    n_righe <= "00000000";
						    currentPixel <= "00000000";
						    newPixel <= "00000000";
						    maxPixelValue <= "00000000";
						    minPixelValue <= "11111111";
							n_pixel <= "0000000000000000";
						    o_add<= "0000000000000000";
						    o_address <= "0000000000000000";
							o_en<='0';
							o_we<='0';
						    o_done <= '0';                        ----vedere se non manca qualcosa da inizalizzare
						  
						   --if bla bla change state
						    if(i_start='1') then
						        NEXT_STATE <= START;
						    else
						        NEXT_STATE <= RESET;
							end if;
							
                  when START =>
                            o_en <= '1';
						    o_we <= '0';
						    contatore <= "0000000000000000";
						  --go to SET_ADDRESS state
			   			    NEXT_STATE <= READ_COLUMN;
			   			    
                  when READ_COLUMN =>
                             n_col <= unsigned(i_data);
							 NEXT_STATE <= ROW_ADDRESS;
                             
                  when ROW_ADDRESS =>
                             o_add <= "0000000000000001";
							 o_address <= o_add;
							 NEXT_STATE<=READ_ROW;
							 
                  when READ_ROW =>
                                 n_righe <= unsigned(i_data);
								 n_pixel <= n_col*n_righe;
								 if TO_INTEGER(n_righe)>0 then
					           	     contatore <= "0000000000000000";
								     o_add <= "0000000000000010";
							         o_address <= o_add;
								     NEXT_STATE <= READ_PIXEL;
								 else
								     o_en<='1';
								     o_add <= "0000000000000001";
							     	 o_address <= o_add;
								     NEXT_STATE<=READ_ROW;
								 end if;
                  when READ_PIXEL =>
					         if(contatore=n_pixel) then
					                    o_add <= "0000000000000010";
										o_address <= o_add;
										NEXT_STATE <= DELTA_VALUE;
							 else
							            tempPixel<=unsigned(i_data);
									    if(unsigned(i_data) > maxPixelValue) then
										   maxPixelValue <= unsigned(i_data);
										elsif(unsigned(i_data) < minPixelValue) then
										   minPixelValue <= unsigned(i_data);
										end if;
										contatore <= contatore+"0000000000000001";
									    o_en <= '1';
									    o_add <= o_add + "0000000000000001";
                                        o_address <= o_add;
									    NEXT_STATE <= READ_PIXEL;
							 end if;
							 
                  when DELTA_VALUE =>
                    		 deltaValue<= TO_INTEGER(maxPixelValue-minPixelValue);
							 NEXT_STATE <= SHIFT_LEVEL;
							 
                  when SHIFT_LEVEL => 
                             if (deltaValue=0) then
                                       shiftLevel<=8;
                             elsif (deltaValue<3 AND deltaValue>0) then
                                       shiftLevel<=7;
                             elsif (deltaValue>=3 AND deltaValue<7) then
                                       shiftLevel<=6;
                             elsif (deltaValue>=7 AND deltaValue<15) then
                                       shiftLevel<=5;
                             elsif (deltaValue>=15 AND deltaValue<31) then
                                       shiftLevel<=4;
                             elsif (deltaValue>=31 AND deltaValue<63) then
                                       shiftLevel<=3;
                             elsif (deltaValue>=63 AND deltaValue<127) then
                                       shiftLevel<=2;
                             elsif (deltaValue>=127 AND deltaValue<255) then
                                       shiftLevel<=1;
                             elsif (deltaValue=255) then
                                       shiftLevel<=0;
                             end if;
                             
							 o_en <='1';
							 contatore <= "0000000000000000";
							 NEXT_STATE <= READ_PIXEL_AGAIN;
							 
                  when READ_PIXEL_AGAIN =>
                             o_en <='0';
							 if(contatore=n_pixel) then
									    NEXT_STATE <= DONE;
							 else
									    contatore <= contatore+"0000000000000001";
									    tempPixel<=shift_left((unsigned(i_data)-minPixelValue), shiftLevel);
										NEXT_STATE <= CALCULATE_NEW_VALUE;
							 end if;
							 
                  when CALCULATE_NEW_VALUE =>
                             if tempPixel<255 then
                                       newPixel <= tempPixel;
                             else
                                       newPixel <= to_unsigned(255, 8);
                             end if;
                             o_add_prec <= o_add;
						     NEXT_STATE <= WRITE_OUTPUT;
									
                  when WRITE_OUTPUT =>
                    		 o_add<=std_logic_vector(unsigned(o_add)+n_pixel);
							 o_address <= o_add;
							 o_data <= std_logic_vector(newPixel);
							 o_en <='1';
							 o_we <='1';
							 NEXT_STATE <= RESET_ADDRESS;
							 
                  when RESET_ADDRESS =>
                    		 o_add <= o_add_prec;
                    		 o_add <= o_add + "0000000000000001";
                    		 o_address <= o_add;
							 o_en <='1';
							 o_we <='0';
							 NEXT_STATE<=READ_PIXEL_AGAIN;
							 
                  when DONE =>
                    				o_done<='1';
                  when others => null;
               end case;      									
			end if;
		 end process;

end Behavioral;
