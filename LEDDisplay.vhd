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
    
    component ram_dual is
        port
        (
            clock1        : IN std_logic ;
            clock2        : IN std_logic ;
            data          : IN std_logic_vector (31 DOWNTO 0);
            write_address : IN integer RANGE 0 to 16383;
            read_address  : IN integer RANGE 0 to 16383;
            we            : IN std_logic ;
            q             : OUT std_logic_vector (31 DOWNTO 0)
        );
    end component;
    
    TYPE UART_Data_Array IS ARRAY (natural range <>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    component UART_Array is
        generic
        (
            CLK_Frequency : INTEGER  := 96000000;
            Baudrate      : NATURAL  := 9600;
            Parity        : INTEGER  := 0;
            Parity_EO     : STD_LOGIC  := '0';
            RX_Timeout    : NATURAL  := 100;
            Max_Bytes     : NATURAL  := 4
        );
        port
        (
            CLK           : IN STD_LOGIC;
            Reset         : IN STD_LOGIC  := '0';
            RX            : IN STD_LOGIC  := '1';
            TX            : OUT STD_LOGIC  := '1';
            TX_Enable     : IN STD_LOGIC  := '0';
            TX_Bytes      : IN NATURAL range 0 to max_bytes := 0;
            TX_Data       : IN UART_Data_Array (max_bytes-1 downto 0) := (others => (others => '0'));
            TX_Busy       : OUT STD_LOGIC  := '0';
            RX_Bytes      : OUT NATURAL range 0 to max_bytes := 0;
            RX_Data       : OUT UART_Data_Array (max_bytes-1 downto 0) := (others => (others => '0'));
            RX_Busy       : OUT STD_LOGIC  := '0';
            RX_Error      : OUT STD_LOGIC  := '0'
        );
    end component;
    
    signal RESET : std_logic := '1';
    
    signal row : std_logic_vector (4 downto 0) := "00000";
    signal PWM_Counter : integer range 0 to 31 := 0;
    
    TYPE MAIN_STATE_TYPE IS (SET_ROW, UPDATE_ROW, SHIFT_STATE_1, SHIFT_STATE_2, SHIFT_STATE_3, SHIFT_STATE_4, WAIT_STATE, BLANK, UNBLANK, UNLATCH);
    signal MAIN_STATE : MAIN_STATE_TYPE := WAIT_STATE;
    
    
    signal CLK_48 : std_logic;
    signal CLK_96: std_logic ;
    
    signal RAM_Data_In : std_logic_vector(31 downto 0);
    signal RAM_Write_Address : integer RANGE 0 to 16383;
    signal RAM_Read_Address : integer RANGE 0 to 16383;
    signal RAM_Write_Enable : std_logic;
    signal RAM_Data_Out : std_logic_vector(31 downto 0);

    signal RX_Bytes      : NATURAL range 0 to 3;
    signal RX_Data       : UART_Data_Array (3 downto 0);
    signal RX_Busy       : STD_LOGIC;
    signal RX_Error      : STD_LOGIC;
    
    signal last_Rx_Busy : std_logic;
    signal last_last_Rx_Busy : std_logic;
begin
    PLL_1: PLL
    port map
    (
        inclk0 => CLK,
        c0     => CLK_48,
        c1     => CLK_96 --60M
    );
    
    RAM_1: ram_dual
    port map
    (
        clock1        => CLK_96,
        clock2        => CLK_96,
        data          => RAM_Data_In,
        write_address => RAM_Write_Address,
        read_address  => RAM_Read_Address,
        we            => RAM_Write_Enable,
        q             => RAM_Data_Out
    );
    
    UART_1: UART_Array
    generic map
    (
        CLK_Frequency => 60000000,
        Baudrate      => 460800,
        Parity        => 0,
        Parity_EO     => '0',
        RX_Timeout    => 100,
        Max_Bytes     => 4
    )
    port map
    (
        CLK           => CLK_96,
        Reset         => RESET,
        RX            => uart_Rx,
        TX            => open,
        TX_Enable     => open,
        TX_Bytes      => open,
        TX_Data       => open,
        TX_Busy       => open,
        RX_Bytes      => RX_Bytes,
        RX_Data       => RX_Data,
        RX_Busy       => RX_Busy,
        RX_Error      => RX_Error
    );

    process(CLK_96, RESET)
    variable column : integer range 0 to 256 := 0;
    begin
        if RESET = '1' then
            column := 0;
            row <= "00000";
            PWM_Counter <= 0;
            RESET <= '0';
            MAIN_STATE <= WAIT_STATE;
        elsif rising_edge(CLK_96) then
            case (MAIN_STATE) is
                when UPDATE_ROW =>
                    row <= std_logic_vector( unsigned(row) + 1 );
                    MAIN_STATE <= SHIFT_STATE_1;
                    
                when SHIFT_STATE_1=>
                    
                    CLOCK <= '0';
                    --load from RAM
                    RAM_Read_Address <= (to_integer(unsigned(row))*256) + column;
                    MAIN_STATE <= SHIFT_STATE_2;

                when SHIFT_STATE_2 =>
                    MAIN_STATE <= SHIFT_STATE_3;
                    
                when SHIFT_STATE_3 =>
                    if(to_unsigned(PWM_Counter, 5) < unsigned(RAM_Data_Out(29 DOWNTO 25))) then
                        R1 <= '1';
                    else
                        R1 <= '0';
                    end if;
                    
                    if(to_unsigned(PWM_Counter, 5) < unsigned(RAM_Data_Out(24 DOWNTO 20))) then
                        G1 <= '1';
                    else
                        G1 <= '0';
                    end if;
                    
                    if(to_unsigned(PWM_Counter, 5) < unsigned(RAM_Data_Out(19 DOWNTO 15))) then
                        B1 <= '1';
                    else
                        B1 <= '0';
                    end if;

                    
                    if(to_unsigned(PWM_Counter, 5) < unsigned(RAM_Data_Out(14 DOWNTO 10))) then
                        R2 <= '1';
                    else
                        R2 <= '0';
                    end if;

                    if(to_unsigned(PWM_Counter, 5) < unsigned(RAM_Data_Out(9 DOWNTO 5))) then
                        G2 <= '1';
                    else
                        G2 <= '0';
                    end if;

                    if(to_unsigned(PWM_Counter, 5) < unsigned(RAM_Data_Out(4 DOWNTO 0))) then
                        B2 <= '1';
                    else
                        B2 <= '0';
                    end if;
                    
                    
                    MAIN_STATE <= SHIFT_STATE_4;
                when SHIFT_STATE_4 =>
                    CLOCK <= '1';
                    column := column + 1;
                    if(column > 255) then
                        column := 0;
                        MAIN_STATE <= BLANK;
                    else
                        MAIN_STATE <= SHIFT_STATE_1;
                    end if;
                    
                when BLANK =>
                    OE <= '1';
                    MAIN_STATE <= SET_ROW;
                    
                when SET_ROW =>
                    A <= row(0);
                    B <= row(1);
                    C <= row(2);
                    D <= row(3);
                    E <= row(4);
                    if UNSIGNED(row) = 0 then
                        --increment PWM counter
                        PWM_Counter <= PWM_Counter + 1;
                    end if;
                    MAIN_STATE <= UNLATCH;
                    
                when UNLATCH =>
                    LATCH <= '1';
                    MAIN_STATE <= UNBLANK;
                    
                when UNBLANK =>
                    LATCH <= '0';
                    OE <= '0';
                    MAIN_STATE <= WAIT_STATE;
                    
                when WAIT_STATE =>
                    MAIN_STATE <= UPDATE_ROW;
                    
            end case;
        end if;
    end process;
    
    process(CLK_96)
    variable uart_receive_counter : integer range 0 to 16383 := 0; --0 to max pixel
    begin
        if rising_edge(CLK_96) then
            last_Rx_Busy <= RX_Busy;
            if (last_Rx_Busy = '1' and RX_Busy = '0') then --if finished receiving
                RAM_Data_In <= RX_Data(0) & RX_Data(1) & RX_Data(2) & RX_Data(3);
                --if word starts with a one, then reset the receive counter.
                if RX_Data(0)(7) = '1' then
                    uart_receive_counter := 0;
                else
                    uart_receive_counter := uart_receive_counter + 1;
                end if;
                RAM_Write_Address <= uart_receive_counter;
                RAM_Write_Enable <= '1';
            else
                RAM_Write_Enable <= '0';
            end if;
        end if;
    end process;
    
end architecture rtl;