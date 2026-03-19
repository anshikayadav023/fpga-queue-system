-- File: fsm_controller.vhd
-- Moore FSM controller for Smart Queue Token Dispenser (Block 1)
-- Five states: IDLE, ISSUE_TOKEN, WAIT_FOR_SERVICE, NEXT_CALL, RESET
-- Synchronous to clk. Active-low global reset rst_n.
-- Inputs expected to be debounced and synchronized button signals from Block 2.
-- Signals:
--  clk           : in  std_logic; -- 50 MHz system clock
--  rst_n         : in  std_logic; -- active low reset
--  btn_issue     : in  std_logic; -- request to issue next token (debounced)
--  btn_next      : in  std_logic; -- operator 'next' / call next customer (debounced)
--  btn_reset     : in  std_logic; -- reset counters/display (debounced)
--  svc_done      : in  std_logic; -- optional: indicates service finished (can be tied low if unused)
-- Outputs (Moore: depend only on present state):
--  issue_pulse         : out std_logic; -- one-cycle pulse while in ISSUE_TOKEN
--  next_pulse          : out std_logic; -- one-cycle pulse while in NEXT_CALL
--  reset_pulse         : out std_logic; -- one-cycle pulse while in RESET
--  en_next_token       : out std_logic; -- enable to increment Next Token counter
--  en_now_serving      : out std_logic; -- enable to increment Now Serving counter
--  state_led           : out std_logic_vector(2 downto 0); -- debug LEDs for state

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_controller is
    port(
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        btn_issue   : in  std_logic;
        btn_next    : in  std_logic;
        btn_reset   : in  std_logic;
        svc_done    : in  std_logic;

        issue_pulse : out std_logic;
        next_pulse  : out std_logic;
        reset_pulse : out std_logic;
        en_next_token : out std_logic;
        en_now_serving: out std_logic;
        state_led   : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of fsm_controller is

    type state_type is (S_IDLE, S_ISSUE_TOKEN, S_WAIT_FOR_SERVICE, S_NEXT_CALL, S_RESET);
    signal state, next_state : state_type;

begin

    -- Synchronous state register (D flip-flops)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= S_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Next-state logic and Moore outputs
    process(state, btn_issue, btn_next, btn_reset, svc_done)
        -- default outputs for Moore machine
        variable v_issue_pulse    : std_logic := '0';
        variable v_next_pulse     : std_logic := '0';
        variable v_reset_pulse    : std_logic := '0';
        variable v_en_next_token  : std_logic := '0';
        variable v_en_now_serving : std_logic := '0';
        variable v_state_led      : std_logic_vector(2 downto 0) := (others => '0');
    begin
        -- defaults
        v_issue_pulse    := '0';
        v_next_pulse     := '0';
        v_reset_pulse    := '0';
        v_en_next_token  := '0';
        v_en_now_serving := '0';
        v_state_led      := ("000");

        -- state decoding (Moore outputs depend only on state)
        case state is
            when S_IDLE =>
                v_state_led := "000";
                -- transitions
                if btn_reset = '1' then
                    next_state <= S_RESET;
                elsif btn_issue = '1' then
                    next_state <= S_ISSUE_TOKEN;
                elsif btn_next = '1' then
                    next_state <= S_NEXT_CALL;
                else
                    next_state <= S_IDLE;
                end if;

            when S_ISSUE_TOKEN =>
                v_state_led := "001";
                v_issue_pulse := '1';
                v_en_next_token := '1';
                -- After issuing a token, move to waiting for service
                next_state <= S_WAIT_FOR_SERVICE;

            when S_WAIT_FOR_SERVICE =>
                v_state_led := "010";
                -- In waiting state, operator can press next to call the next customer
                if btn_reset = '1' then
                    next_state <= S_RESET;
                elsif btn_next = '1' then
                    next_state <= S_NEXT_CALL;
                elsif svc_done = '1' then
                    -- optional: if a service-done sensor is provided, return to IDLE
                    next_state <= S_IDLE;
                else
                    next_state <= S_WAIT_FOR_SERVICE;
                end if;

            when S_NEXT_CALL =>
                v_state_led := "011";
                v_next_pulse := '1';
                v_en_now_serving := '1';
                -- After calling next, return to IDLE
                next_state <= S_IDLE;

            when S_RESET =>
                v_state_led := "100";
                v_reset_pulse := '1';
                -- hold reset pulse one cycle then go to IDLE
                next_state <= S_IDLE;

            when others =>
                v_state_led := "111";
                next_state <= S_IDLE;
        end case;

        -- assign outputs (combinational in Moore machine)
        issue_pulse    <= v_issue_pulse;
        next_pulse     <= v_next_pulse;
        reset_pulse    <= v_reset_pulse;
        en_next_token  <= v_en_next_token;
        en_now_serving <= v_en_now_serving;
        state_led      <= v_state_led;
    end process;

end architecture;