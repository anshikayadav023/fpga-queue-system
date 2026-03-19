library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity queue_system_top is
    port(
        clk        : in  std_logic;     -- 50 MHz clock
        rst_n      : in  std_logic;     -- Active-low system reset

        btn_issue_raw : in std_logic;   -- KEY0
        btn_next_raw  : in std_logic;   -- KEY1
        btn_reset_raw : in std_logic;   -- SW2 (or KEY2 if available)

        -- 7-segment displays (active-low)
        HEX0 : out std_logic_vector(6 downto 0);
        HEX1 : out std_logic_vector(6 downto 0);
        HEX2 : out std_logic_vector(6 downto 0);
        HEX3 : out std_logic_vector(6 downto 0);

        -- LEDs
        LEDR : out std_logic_vector(1 downto 0)
    );
end entity;


architecture rtl of queue_system_top is

    -------------------------------------------------------------------------
    -- INTERNAL WIRES (these MUST NOT appear in Pin Planner)
    -------------------------------------------------------------------------

    -- From Block 3 (debouncer) to FSM
    signal btn_issue_clean : std_logic;
    signal btn_next_clean  : std_logic;
    signal btn_reset_clean : std_logic;

    -- From FSM to counters
    signal en_next_token   : std_logic;
    signal en_now_serving  : std_logic;
    signal reset_pulse     : std_logic;

    -- From counters to display
    signal nt_d1, nt_d0 : std_logic_vector(3 downto 0);
    signal ns_d1, ns_d0 : std_logic_vector(3 downto 0);

    -- FSM state LEDs
    signal state_led_s : std_logic_vector(2 downto 0);

    signal busy_s  : std_logic;
    signal ready_s : std_logic;

begin

    -------------------------------------------------------------------------
    -- BLOCK 3 + 4: INPUT PROCESSING + COUNTERS
    -------------------------------------------------------------------------
    io_block_inst : entity work.queue_io_block
        port map(
            clk        => clk,
            rst_n      => rst_n,

            btn_issue_raw => btn_issue_raw,
            btn_next_raw  => btn_next_raw,
            btn_reset_raw => btn_reset_raw,

            en_next_token   => en_next_token,
            en_now_serving  => en_now_serving,
            reset_pulse     => reset_pulse,

            btn_issue_clean => btn_issue_clean,
            btn_next_clean  => btn_next_clean,
            btn_reset_clean => btn_reset_clean,

            next_token_d1   => nt_d1,
            next_token_d0   => nt_d0,
            now_serving_d1  => ns_d1,
            now_serving_d0  => ns_d0
        );

    -------------------------------------------------------------------------
    -- BLOCK 1: FSM CONTROLLER
    -------------------------------------------------------------------------
    fsm_inst : entity work.fsm_controller
        port map(
            clk        => clk,
            rst_n      => rst_n,

            btn_issue  => btn_issue_clean,
            btn_next   => btn_next_clean,
            btn_reset  => btn_reset_clean,

            svc_done   => '0',  -- unused

            issue_pulse    => open,
            next_pulse     => open,
            reset_pulse    => reset_pulse,

            en_next_token  => en_next_token,
            en_now_serving => en_now_serving,

            state_led      => state_led_s
        );

    -------------------------------------------------------------------------
    -- BUSY / READY LEDs (based on state of FSM)
    -------------------------------------------------------------------------
    busy_s  <= '1' when state_led_s = "010" else '0';  -- WAIT_FOR_SERVICE
    ready_s <= '1' when state_led_s = "000" else '0';  -- IDLE

    LEDR(0) <= busy_s;   -- Busy LED
    LEDR(1) <= ready_s;  -- Ready LED

    -------------------------------------------------------------------------
    -- BLOCK 2: DISPLAY OUTPUT LOGIC
    -------------------------------------------------------------------------
    display_inst : entity work.display_output_logic
        port map(
            next_tens   => nt_d1,
            next_units  => nt_d0,
            now_tens    => ns_d1,
            now_units   => ns_d0,

            busy        => busy_s,
            ready       => ready_s,

            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,

            LEDR0 => open,
            LEDR1 => open
        );

end architecture;