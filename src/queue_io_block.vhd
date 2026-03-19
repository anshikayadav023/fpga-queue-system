library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ================================================================
-- SINGLE FILE: INPUT PROCESSING + TWO COUNTERS (00–99)
-- Outputs are ready to connect to FSM
-- ================================================================

entity queue_io_block is
    port(
        clk        : in  std_logic;
        rst_n      : in  std_logic;

        -- raw buttons from hardware
        btn_issue_raw : in  std_logic;
        btn_next_raw  : in  std_logic;
        btn_reset_raw : in  std_logic;

        -- enable signals from FSM
        en_next_token   : in std_logic;
        en_now_serving  : in std_logic;
        reset_pulse     : in std_logic;

        -- clean 1-cycle pulses TO FSM
        btn_issue_clean : out std_logic;
        btn_next_clean  : out std_logic;
        btn_reset_clean : out std_logic;

        -- counter outputs (BCD)
        next_token_d1   : out std_logic_vector(3 downto 0);
        next_token_d0   : out std_logic_vector(3 downto 0);
        now_serving_d1  : out std_logic_vector(3 downto 0);
        now_serving_d0  : out std_logic_vector(3 downto 0)
    );
end entity;


architecture rtl of queue_io_block is

    ------------------------------------------------------------------
    -- Signals for debounce
    ------------------------------------------------------------------
    signal i_sync0, i_sync1 : std_logic := '0';
    signal n_sync0, n_sync1 : std_logic := '0';
    signal r_sync0, r_sync1 : std_logic := '0';

    signal i_state, n_state, r_state : std_logic := '0';
    signal i_cnt, n_cnt, r_cnt : unsigned(15 downto 0) := (others => '0');

    signal i_pulse, n_pulse, r_pulse : std_logic := '0';

    ------------------------------------------------------------------
    -- Signals for counters
    ------------------------------------------------------------------
    signal nt_tens, nt_ones : unsigned(3 downto 0) := (others => '0');
    signal ns_tens, ns_ones : unsigned(3 downto 0) := (others => '0');

begin

    ------------------------------------------------------------------
    -- ========== INPUT PROCESSING (3x debounce + sync) ==========
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- SYNC
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            -- ISSUE button sync
            i_sync0 <= btn_issue_raw;
            i_sync1 <= i_sync0;

            -- NEXT button sync
            n_sync0 <= btn_next_raw;
            n_sync1 <= n_sync0;

            -- RESET button sync
            r_sync0 <= btn_reset_raw;
            r_sync1 <= r_sync0;

        end if;
    end process;

    ------------------------------------------------------------------
    -- DEBOUNCE + RISING EDGE DETECTOR FOR ALL 3 BUTTONS
    ------------------------------------------------------------------

    process(clk, rst_n)
        variable pi, pn, pr : std_logic := '0';
    begin
        if rst_n = '0' then
            i_state <= '0';  n_state <= '0';  r_state <= '0';
            i_cnt   <= (others => '0');
            n_cnt   <= (others => '0');
            r_cnt   <= (others => '0');
            i_pulse <= '0';  n_pulse <= '0';  r_pulse <= '0';
            pi := '0'; pn := '0'; pr := '0';

        elsif rising_edge(clk) then

            ---------------- ISSUE ----------------
            if i_sync1 /= i_state then
                i_cnt <= i_cnt + 1;
                if i_cnt = 50000 then
                    i_state <= i_sync1;
                    i_cnt   <= (others => '0');
                end if;
            else
                i_cnt <= (others => '0');
            end if;

            i_pulse <= '0';
            if pi = '0' and i_state = '1' then
                i_pulse <= '1';
            end if;
            pi := i_state;

            ---------------- NEXT ----------------
            if n_sync1 /= n_state then
                n_cnt <= n_cnt + 1;
                if n_cnt = 50000 then
                    n_state <= n_sync1;
                    n_cnt   <= (others => '0');
                end if;
            else
                n_cnt <= (others => '0');
            end if;

            n_pulse <= '0';
            if pn = '0' and n_state = '1' then
                n_pulse <= '1';
            end if;
            pn := n_state;

            ---------------- RESET ----------------
            if r_sync1 /= r_state then
                r_cnt <= r_cnt + 1;
                if r_cnt = 50000 then
                    r_state <= r_sync1;
                    r_cnt   <= (others => '0');
                end if;
            else
                r_cnt <= (others => '0');
            end if;

            r_pulse <= '0';
            if pr = '0' and r_state = '1' then
                r_pulse <= '1';
            end if;
            pr := r_state;

        end if;
    end process;

    ------------------------------------------------------------------
    -- OUTPUT CLEAN BUTTON PULSES
    ------------------------------------------------------------------
    btn_issue_clean <= i_pulse;
    btn_next_clean  <= n_pulse;
    btn_reset_clean <= r_pulse;


    ------------------------------------------------------------------
    -- ========== COUNTERS (00–99) ==========
    ------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then

            nt_tens <= (others => '0');  nt_ones <= (others => '0');
            ns_tens <= (others => '0');  ns_ones <= (others => '0');

        elsif rising_edge(clk) then

            ------------------------------------------------------
            -- RESET BOTH COUNTERS (FROM FSM reset_pulse)
            ------------------------------------------------------
            if reset_pulse = '1' then
                nt_tens <= (others => '0');  nt_ones <= (others => '0');
                ns_tens <= (others => '0');  ns_ones <= (others => '0');
            end if;

            ------------------------------------------------------
            -- NEXT TOKEN COUNTER
            ------------------------------------------------------
            if en_next_token = '1' then

                if nt_ones = 9 then
                    nt_ones <= (others => '0');

                    if nt_tens = 9 then
                        nt_tens <= (others => '0');    -- wrap 99→00
                    else
                        nt_tens <= nt_tens + 1;
                    end if;

                else
                    nt_ones <= nt_ones + 1;
                end if;

            end if;

            ------------------------------------------------------
            -- NOW SERVING COUNTER
            ------------------------------------------------------
            if en_now_serving = '1' then

                if ns_ones = 9 then
                    ns_ones <= (others => '0');

                    if ns_tens = 9 then
                        ns_tens <= (others => '0');    -- wrap 99→00
                    else
                        ns_tens <= ns_tens + 1;
                    end if;

                else
                    ns_ones <= ns_ones + 1;
                end if;

            end if;

        end if;
    end process;

    next_token_d1  <= std_logic_vector(nt_tens);
    next_token_d0  <= std_logic_vector(nt_ones);
    now_serving_d1 <= std_logic_vector(ns_tens);
    now_serving_d0 <= std_logic_vector(ns_ones);

end architecture;