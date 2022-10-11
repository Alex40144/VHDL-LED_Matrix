library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity LEDDisplay is
    port(
        CLK : in std_logic;
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
        OE : out std_logic := '0';
        
        uart_Rx : in std_logic
    );
end entity LEDDisplay;

architecture rtl of LEDDisplay is
    signal counter : integer range 0 to 1000000 := 0;
    signal column : integer range 0 to 64 := 0;
    signal row : std_logic_vector (4 downto 0) := "00000";
    signal pixel :integer range 0 to 6144;
    signal PWM_Counter : integer range 0 to 255 := 0;
    
    TYPE MAIN_STATE_TYPE IS (SET_ROW, SHIFT_STATE_1, SHIFT_STATE_2, SHIFT_STATE_3, WAIT_STATE, BLANK, UNBLANK);
    signal MAIN_STATE : MAIN_STATE_TYPE := WAIT_STATE;
    
    type t_matrix is array (0 to 2) of integer range 0 to 255; --r,g,b
    signal DATA : t_matrix := (others=>0);
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            counter <= counter + 1;
            case (MAIN_STATE) is
                when SET_ROW =>
                    row <= std_logic_vector( unsigned(row) + 1 );
                    A <= row(0);
                    B <= row(1);
                    C <= row(2);
                    D <= row(3);
                    E <= row(4);
                    
                    --increment PWM counter
                    PWM_Counter <= PWM_Counter + 1;
                    
                    MAIN_STATE <= SHIFT_STATE_1;
                when SHIFT_STATE_1=>
                    CLOCK <= '0';
                    --generate data in this state to avoid variables
                    if(pixel + unsigned(row) < 85) then
                        DATA <= ((pixel + unsigned(row)) * 3, 255 - (pixel + unsigned(row)), 0);
                    else if (pixel + row < 170) then
                        DATA <= ((255 - pixel + unsigned(row)) * 3, 0, (pixel + unsigned(row)) * 3);
                    else
                        DATA <= (0, (pixel + unsigned(row)) * 3, 255 - pixel + unsigned(row)) * 3);
                    end if;
                    MAIN_STATE <= SHIFT_STATE_2;
                when SHIFT_STATE_2 =>

                    --set data
                    if(Data(0) < PWM_Counter) then
                        R1 <= '1';
                    else
                        R1 <= '0';
                    end if;
                    
                    if(Data(0) < PWM_Counter) then
                        R2 <= '1';
                    else
                        R2 <= '0';
                    end if;
                    
                    if(Data(1) < PWM_Counter) then
                        B1 <= '1';
                    else
                        B1 <= '0';
                    end if;
                    
                    if(Data(1) < PWM_Counter) then
                        B2 <= '1';
                    else
                        B2 <= '0';
                    end if;
                    
                    if(Data(2) < PWM_Counter) then
                        G1 <= '1';
                    else
                        G1 <= '0';
                    end if;
                    
                    if(Data(2) < PWM_Counter) then
                        G2 <= '1';
                    else
                        G2 <= '0';
                    end if;
                    
                    --increment pixel counter
                    pixel <= pixel + 1;
                    
                    MAIN_STATE <= SHIFT_STATE_3;
                when SHIFT_STATE_3 =>
                    CLOCK <= '1';
                    column <= column + 1;
                    if(column > 32) then
                        column <= 0;
                        MAIN_STATE <= BLANK;
                    else
                        MAIN_STATE <= SHIFT_STATE_1;
                    end if;
                when BLANK =>
                    --Blank LEDs
                    OE <= '1';
                    --set address with ABCD
                    --Latch Data to output register
                    LATCH <= '1';
                    MAIN_STATE <= UNBLANK;
                when UNBLANK =>
                    --remove latch signal
                    LATCH <= '0';
                    --enable LEDs
                    OE <= '0';
                    --set state to wait
                    MAIN_STATE <= WAIT_STATE;
                when WAIT_STATE =>
                    --if time has passed then send new data.
                    --this is a sort of frames per second
                    if(counter > 100) then
                        counter <= 0;
                        MAIN_STATE <= SET_ROW;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;