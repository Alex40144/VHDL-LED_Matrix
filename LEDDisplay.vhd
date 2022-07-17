library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package array_type is
end package array_type;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.array_type.all;

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
    
    type t_matrix is array (0 to 192) of integer range 0 to 255;
    signal DATA : t_matrix := (others=>0);

    TYPE UART_STATE_TYPE IS (IDLE, RECEIVE);
    signal UART_STATE : UART_STATE_TYPE := IDLE;
    
    signal scaleCount : integer range 0 to 255 := 0;
    signal bitCounter : integer range 0 to 10 := 0;
    signal byteCounter : integer range 0 to 6144 := 0;
    
    signal uart_Data : std_logic_vector(7 downto 0);
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
                    MAIN_STATE <= SHIFT_STATE_2;
                when SHIFT_STATE_2 =>
                    --set data
                    if(Data(pixel) < PWM_Counter) then
                        R1 <= '1';
                    else
                        R1 <= '0';
                    end if;
                    
                    if(Data(pixel + 2048) < PWM_Counter) then
                        R2 <= '1';
                    else
                        R2 <= '0';
                    end if;
                    
                    if(Data(pixel + 1) < PWM_Counter) then
                        B1 <= '1';
                    else
                        B1 <= '0';
                    end if;
                    
                    if(Data(pixel + 2048 + 1) < PWM_Counter) then
                        B2 <= '1';
                    else
                        B2 <= '0';
                    end if;
                    
                    if(Data(pixel + 2) < PWM_Counter) then
                        G1 <= '1';
                    else
                        G1 <= '0';
                    end if;
                    
                    if(Data(pixel + 2048 + 2) < PWM_Counter) then
                        G2 <= '1';
                    else
                        G2 <= '0';
                    end if;
                    
                    --increment pixel counter
                    pixel <= pixel + 3;
                    
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
                    if(counter > 100) then
                        counter <= 0;
                        MAIN_STATE <= SET_ROW;
                    end if;
            end case;
        end if;
        
        --UART
        if rising_edge(CLK) then
            case (UART_STATE) is
                when IDLE =>
                    if (uart_Rx = '0') then
                        scaleCount <= 0;
                        UART_STATE <= RECEIVE;
                    end if;
                    
                when RECEIVE =>
                    scaleCount <= scaleCount + 1;
                    if (scaleCount > 7) then --115200
                        if (bitCounter < 8) then
                            uart_Data(7 downto 1) <= uart_Data(6 downto 0); --left shift
                            uart_Data(0) <= uart_Rx;
                            bitCounter <= bitCounter + 1;
                            scaleCount <= 0;
                        end if;
                    end if;

                    if (bitCounter = 8) then
                        --received all data.
                        Data(byteCounter) <= TO_INTEGER(SIGNED(uart_Data));
                        byteCounter <= byteCounter + 1;
                        UART_STATE <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;