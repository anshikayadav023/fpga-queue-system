library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_output_logic is
    Port(
        -- BCD inputs (each 4 bits)
        next_tens      : in std_logic_vector(3 downto 0);
        next_units     : in std_logic_vector(3 downto 0);
        now_tens       : in std_logic_vector(3 downto 0);
        now_units      : in std_logic_vector(3 downto 0);

        busy           : in std_logic;  -- LEDR0
        ready          : in std_logic;  -- LEDR1

        HEX0, HEX1     : out std_logic_vector(6 downto 0); -- Now Serving
        HEX2, HEX3     : out std_logic_vector(6 downto 0); -- Next Token

        LEDR0          : out std_logic;
        LEDR1          : out std_logic
    );
end display_output_logic;

architecture rtl of display_output_logic is

    -- 7-segment decoder (common anode)
    function seven_seg(d : std_logic_vector(3 downto 0)) 
        return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case d is
            when "0000" => seg := "1000000"; -- 0
            when "0001" => seg := "1111001"; -- 1
            when "0010" => seg := "0100100"; -- 2
            when "0011" => seg := "0110000"; -- 3
            when "0100" => seg := "0011001"; -- 4
            when "0101" => seg := "0010010"; -- 5
            when "0110" => seg := "0000010"; -- 6
            when "0111" => seg := "1111000"; -- 7
            when "1000" => seg := "0000000"; -- 8
            when "1001" => seg := "0010000"; -- 9
            when others => seg := "1111111"; -- blank
        end case;
        return seg;
    end function;

begin

    -- Now Serving
    HEX0 <= seven_seg(now_units); -- units
    HEX1 <= seven_seg(now_tens);  -- tens

    -- Next Token
    HEX2 <= seven_seg(next_units);
    HEX3 <= seven_seg(next_tens);

    -- LEDs
    LEDR0 <= busy;  -- Busy
    LEDR1 <= ready; -- Ready

end rtl;
