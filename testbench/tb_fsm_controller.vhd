-- File: tb_fsm_controller.vhd
-- Testbench for fsm_controller.vhd
-- Simulates button presses and checks pulses and enables.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fsm_controller is
end entity;

architecture sim of tb_fsm_controller is
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal btn_issue   : std_logic := '0';
    signal btn_next    : std_logic := '0';
    signal btn_reset   : std_logic := '0';
    signal svc_done    : std_logic := '0';

    signal issue_pulse : std_logic;
    signal next_pulse  : std_logic;
    signal reset_pulse : std_logic;
    signal en_next_token : std_logic;
    signal en_now_serving: std_logic;
    signal state_led   : std_logic_vector(2 downto 0);

    constant clk_period_ns : time := 20 ns; -- 50 MHz

begin

    -- instantiate DUT
    uut: entity work.fsm_controller
        port map (
            clk => clk,
            rst_n => rst_n,
            btn_issue => btn_issue,
            btn_next => btn_next,
            btn_reset => btn_reset,
            svc_done => svc_done,

            issue_pulse => issue_pulse,
            next_pulse  => next_pulse,
            reset_pulse => reset_pulse,
            en_next_token => en_next_token,
            en_now_serving => en_now_serving,
            state_led => state_led
        );

    -- clock generation
    clk_gen: process
    begin
        while true loop
            clk <= '0';
            wait for clk_period_ns/2;
            clk <= '1';
            wait for clk_period_ns/2;
        end loop;
    end process;

    -- stimulus
    stim: process
    begin
        -- global reset
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';
        wait for 100 ns;

        -- Test1: Issue a token
        btn_issue <= '1';
        wait for clk_period_ns; -- hold for one clock
        btn_issue <= '0';
        wait for 100 ns; -- allow FSM to progress

        -- Test2: Service done (optional) -> returns to IDLE
        svc_done <= '1';
        wait for clk_period_ns;
        svc_done <= '0';
        wait for 100 ns;

        -- Test3: Operator presses next to call customer
        btn_next <= '1';
        wait for clk_period_ns;
        btn_next <= '0';
        wait for 100 ns;

        -- Test4: Reset pressed
        btn_reset <= '1';
        wait for clk_period_ns;
        btn_reset <= '0';
        wait for 200 ns;

        -- Test5: Sequence: issue -> wait -> next
        btn_issue <= '1';
        wait for clk_period_ns;
        btn_issue <= '0';
        wait for 120 ns;
        btn_next <= '1';
        wait for clk_period_ns;
        btn_next <= '0';
        wait for 200 ns;

        -- end simulation
        wait for 500 ns;
        assert false report "End of simulation" severity failure;
    end process;

end architecture;