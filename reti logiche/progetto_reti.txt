library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity project_reti_logiche is
  port (
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

architecture BEHAVIOUR of project_reti_logiche is         -- tratto da macchina di mealy
  type state_type is(RESET,START,SET_ADDRESS,READ_TYPE_LINE,READ_PIXEL,DELTA_VALUE,READ_PIXEL_AGAIN,CALCULATE_NEW_VALUE,
   WRITE_OUTPUT,RESET_ADDRESS,DONE);         -- aggiungere tutti gli stati
  signal CURRENT_STATE, NEXT_STATE : state_type;
  signal n_col : UNSIGNED(7 downto 0) := "00000000";
  signal n_righe : UNSIGNED(7 downto 0) := "00000000";
  signal currentPixel : UNSIGNED(7 downto 0) := "00000000";
  signal newPixel : UNSIGNED(7 downto 0) := "00000000";         -- forse mi serve per storare il nuovo valore bit
                                                                -- secondo te serve storare l'indirizzo di memoria dove
														        -- scriveremo la nuova immagine?
  signal maxPixelValue : UNSIGNED(7 downto 0) := "00000000";    -- sono variabili che non vanno scritte poi in memoria,
  signal minPixelValue : UNSIGNED(7 downto 0) := "11111111";    -- servono solo dentro il process per calcolare 
  signal tempPixel : UNSIGNED(7 downto 0) := "00000000";
  signal deltaValue : UNSIGNED(7 downto 0) := "00000000";
  signal shiftLevel : UNSIGNED(7 downto 0) := "00000000";
  signal n_pixel : UNSIGNED(15 downto 0) := "0000000000000000";
  signal contatore : UNSIGNED(15 downto 0) := "0000000000000000";

begin
      --scrivere l'inizializzazione, il done etc
	 FSA : process(i_clk, CURRENT_STATE, i_start, i_rst)
	     begin
		    if(i_clk'event and i_clk='1') then
			   if(i_rst='1') then 
			        CURRENT_STATE <= START;
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
						    shiftLevel <= "00000000";
						    o_address <= "0000000000000000";
							n_pixel <= "0000000000000000";
						    o_done <= '0';                        ----vedere se non manca qualcosa da inizalizzare
						  
						   --if bla bla change state
						    if(i_start='1') then
						        NEXT_STATE <= START;
							end if;
						   
					when START => o_en <= '1';
								  o_we <= '0';
								  --go to SET_ADDRESS state
								  NEXT_STATE <= READ_TYPE_LINE;
									   
					when READ_TYPE_LINE => 
					                    if(o_address(0)='0') then
										    n_col <= unsigned(i_data);
											o_address <= "0000000000000001";
											
										else if(o_address(0)='1') then
										    n_righe <= unsigned(i_data);
											n_pixel <= to_n_col*n_righe;      --n pixel calcolo
											NEXT_STATE <= READ_PIXEL;
										end if;
					                   
					when READ_PIXEL =>
									o_address <= o_address + "0000000000000001";
					                if(contatore=n_pixel) then
									    en <= '0';
										o_address <= "0000000000000010";
										NEXT_STATE <= --stato cinque: calcolo delta value
									else
									    if(unsigned(i_data) > maxPixelValue) then
										   maxPixelValue <= unsigned(i_data);
										else if(unsigned(i_data) < minPixelValue) then
										   minPixelValue <= unsigned(i_data);
										end if;
									    en <= '1';
									    NEXT_STATE <= READ_PIXEL;
									end if;
									contatore <= contatore+"0000000000000001";
									
					when DELTA_VALUE =>
					                deltaValue=maxPixelValue-minPixelValue;
									NEXT_STATE <= SHIFT_LEVEL;
					                
					when SHIFT_LEVEL =>
					                shiftLevel = (8 – FLOOR(LOG2(deltaValue +1)));
									o_en <='1';
									contatore <= "0000000000000000";
									NEXT_STATE <= READ_PIXEL_AGAIN;
									
					when READ_PIXEL_AGAIN =>
					                o_en <='0';
									if(contatore=n_pixel) then
									    NEXT_STATE <= DONE;
									else
									    contatore <= contatore+"0000000000000001";
										tempPixel=(unsigned(i_data)-minPixelValue)<<shiftLevel;
										NEXT_STATE <= CALCULATE_NEW_VALUE;
								    end if;
									
					when CALCULATE_NEW_VALUE => 
					                
					                o_data <= std_logic_vector(MIN(255,tempPixel));
									NEXT_STATE <= WRITE_OUTPUT;
									
					when WRITE_OUTPUT =>
					                o_address <= std_logic_vector(unsigned(o_address) + n_pixel);
									o_en <='1';
									o_we <='1';
									NEXT_STATE <= RESET_ADDRESS;
									
					when RESET_ADDRESS =>
					                o_address <= std_logic_vector(unsigned(o_address) - n_pixel);
									o_en <='1';
									o_we <= '0';
									NEXT_STATE<=READ_PIXEL_AGAIN;
					
					when DONE =>
                                    o_done<='1';
                                    									
			end if;
		 end process;
   
 
end;