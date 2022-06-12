library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LEDDisplay is
    port(
        CLK : in     std_logic;
        R1 : out std_logic := '0';
        R2 : out std_logic := '0';
        G1 : out std_logic := '0';
        G2 : out std_logic := '0';
        B1 : out std_logic := '0';
        B2 : out std_logic := '0';
        A : out std_logic := '0';
        B : out std_logic := '0';
        C : out std_logic := '0';
        D : out std_logic := '0';
        E : out std_logic := '0';
        LATCH : out std_logic := '0';
        CLOCK : out std_logic := '0';
        OE : out std_logic := '0'
    );
end entity LEDDisplay;

architecture rtl of LEDDisplay is
    signal counter : integer range 0 to 1000000 := 0;
    signal column : integer range 0 to 64 := 0;
    signal row : std_logic_vector (4 downto 0) := "00000";

    
    TYPE STATE_TYPE IS (SET_ROW, SHIFT_STATE_1, SHIFT_STATE_2, SHIFT_STATE_3, WAIT_STATE, BLANK, UNBLANK);
    signal STATE : STATE_TYPE := WAIT_STATE;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            counter <= counter + 1;
            case (STATE) is
                when SET_ROW =>
                    row <= std_logic_vector( unsigned(row) + 1 );
                    A <= row(0);
                    B <= row(1);
                    C <= row(2);
                    D <= row(3);
                    E <= row(4);
                    STATE <= SHIFT_STATE_1;
                when SHIFT_STATE_1=>
                    CLOCK <= '0';
                    STATE <= SHIFT_STATE_2;
                when SHIFT_STATE_2 =>
                    --set data
                    R1 <= '1';
                    R2 <= '1';
                    B1 <= '1';
                    B2 <= '1';
                    G1 <= '1';
                    G2 <= '1';
                    STATE <= SHIFT_STATE_3;
                when SHIFT_STATE_3 =>
                    CLOCK <= '1';
                    column <= column + 1;
                    if(column > 32) then
                        column <= 0;
                        STATE <= BLANK;
                    else
                        STATE <= SHIFT_STATE_1;
                    end if;
                when BLANK =>
                    --Blank LEDs
                    OE <= '1';
                    --set address with ABCD
                    --Latch Data to output register
                    LATCH <= '1';
                    STATE <= UNBLANK;
                when UNBLANK =>
                    --remove latch signal
                    LATCH <= '0';
                    --enable LEDs
                    OE <= '0';
                    --set state to wait
                    STATE <= WAIT_STATE;
                when WAIT_STATE =>
                    --if time has passed then send new data.
                    if(counter > 1000) then
                        counter <= 0;
                        STATE <= SET_ROW;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;