library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

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
    component PLL is
        port
        (
            inclk0 : in STD_LOGIC ;
            c0     : OUT STD_LOGIC ;
            c1     : OUT STD_LOGIC
        );
    end component;
    
    signal counter : integer range 0 to 10000 := 0;
    signal column : integer range 0 to 64 := 0;
    signal row : std_logic_vector (4 downto 0) := "00000";
    signal pixel :integer range 0 to 6143;
    signal PWM_Counter : integer range 0 to 255 := 0;
    
    TYPE MAIN_STATE_TYPE IS (SET_ROW, SHIFT_STATE_1, SHIFT_STATE_2, SHIFT_STATE_3, WAIT_STATE, BLANK, UNBLANK);
    signal MAIN_STATE : MAIN_STATE_TYPE := WAIT_STATE;
    
    type t_matrix is array (0 to 2) of integer range 0 to 255; --r,g,b
    signal Data : t_matrix := (others=>0);
    
    signal CLK_48 : std_logic;
    signal CLK_96: std_logic ;

begin
    
    Data(0) <= 150;
    Data(1) <= 150;
    Data(2) <= 0;
    
    PLL_1: PLL
    port map
    (
        inclk0 => CLK,
        c0     => CLK_48,
        c1     => CLK_96
    );


    process(CLK)
    begin
        if rising_edge(CLK) then
            case (MAIN_STATE) is
                when SET_ROW =>
                    row <= std_logic_vector( unsigned(row) + 1 );
                    A <= row(0);
                    B <= row(1);
                    C <= row(2);
                    D <= row(3);
                    E <= row(4);
                    
                    
                    MAIN_STATE <= SHIFT_STATE_1;
                when SHIFT_STATE_1=>
                    if UNSIGNED(row) = 0 then
                        --increment PWM counter
                        PWM_Counter <= PWM_Counter + 1;
                    end if;
                    CLOCK <= '0';
                    MAIN_STATE <= SHIFT_STATE_2;
                when SHIFT_STATE_2 =>
                    if(PWM_Counter < DATA(0)) then
                        R1 <= '1';
                    else
                        R1 <= '0';
                    end if;
                    
                    if(PWM_Counter < DATA(0)) then
                        R2 <= '1';
                    else
                        R2 <= '0';
                    end if;
                    
                    if(PWM_Counter < DATA(1)) then
                        G1 <= '1';
                    else
                        G1 <= '0';
                    end if;
                    
                    if(PWM_Counter < DATA(1)) then
                        G2 <= '1';
                    else
                        G2 <= '0';
                    end if;
                    
                    if(PWM_Counter < DATA(2)) then
                        B1 <= '1';
                    else
                        B1 <= '0';
                    end if;
                    
                    if(PWM_Counter < DATA(2)) then
                        B2 <= '1';
                    else
                        B2 <= '0';
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
                    counter <= counter + 1;
                    if(counter > 10) then
                        counter <= 0;
                        MAIN_STATE <= SET_ROW;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;