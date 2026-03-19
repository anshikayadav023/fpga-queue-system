library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity queue_io_block is
    port(
        clk        : in  std_logic;
        rst_n      : in  std_logic;

        btn_issue_raw : in  std_logic;
        btn_next_raw  : in  std_logic;
        btn_reset_raw : in  std_logic;

        en_next_token   : in std_logic;
        en_now_serving  : in std_logic;
        reset_pulse     : in std_logic;

        btn_issue_clean : out std_logic;
        btn_next_clean  : out std_logic;
        btn_reset_clean : out std_logic;

        next_token_d1   : out std_logic_vector(3 downto 0);
        next_token_d0   : out std_logic_vector(3 downto 0);
        now_serving_d1  : out std_logic_vector(3 downto 0);
        now_serving_d0  : out std_logic_vector(3 downto 0);

        next_token_val  : out std_logic_vector(7 downto 0);
        now_serving_val : out std_logic_vector(7 downto 0)
    );
end entity;


architecture rtl of queue_io_block is

    ---------------------------------------------------------------------
    -- Synchronizers
    ---------------------------------------------------------------------
    signal i_sync0, i_sync1 : std_logic := '0';
    signal n_sync0, n_sync1 : std_logic := '0';
    signal r_sync0, r_sync1 : std_logic := '0';

    ---------------------------------------------------------------------
    -- Debounce + Edge detect
    ---------------------------------------------------------------------
    signal i_state, n_state, r_state : std_logic := '0';
    signal i_prev,  n_prev,  r_prev  : std_logic := '0';

    signal i_cnt, n_cnt, r_cnt : unsigned(15 downto 0) := (others => '0');
    constant DEBOUNCE_MAX : unsigned(15 downto 0) := to_unsigned(50000, 16);

    ---------------------------------------------------------------------
    -- Counters
    ---------------------------------------------------------------------
    signal nt_tens, nt_ones : unsigned(3 downto 0) := (others => '0');
    signal ns_tens, ns_ones : unsigned(3 downto 0) := (others => '0');

begin

    ---------------------------------------------------------------------
    -- 1. SYNC
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            i_sync0 <= btn_issue_raw;  i_sync1 <= i_sync0;
            n_sync0 <= btn_next_raw;   n_sync1 <= n_sync0;
            r_sync0 <= btn_reset_raw;  r_sync1 <= r_sync0;
        end if;
    end process;


    ---------------------------------------------------------------------
    -- 2. DEBOUNCE + EDGE DETECT (legal VHDL)
    ---------------------------------------------------------------------
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            i_state <= '0';  n_state <= '0';  r_state <= '0';
            i_prev <= '0';   n_prev <= '0';   r_prev <= '0';
            i_cnt <= (others => '0');
            n_cnt <= (others => '0');
            r_cnt <= (others => '0');
            btn_issue_clean <= '0';
            btn_next_clean  <= '0';
            btn_reset_clean <= '0';

        elsif rising_edge(clk) then

            ---------------- ISSUE ----------------
            if i_sync1 = i_state then
                i_cnt <= (others => '0');
            else
                i_cnt <= i_cnt + 1;
                if i_cnt = DEBOUNCE_MAX then
                    i_state <= i_sync1;
                    i_cnt <= (others => '0');
                end if;
            end if;

            ---------------- NEXT -----------------
            if n_sync1 = n_state then
                n_cnt <= (others => '0');
            else
                n_cnt <= n_cnt + 1;
                if n_cnt = DEBOUNCE_MAX then
                    n_state <= n_sync1;
                    n_cnt <= (others => '0');
                end if;
            end if;

            ---------------- RESET ----------------
            if r_sync1 = r_state then
                r_cnt <= (others => '0');
            else
                r_cnt <= r_cnt + 1;
                if r_cnt = DEBOUNCE_MAX then
                    r_state <= r_sync1;
                    r_cnt <= (others => '0');
                end if;
            end if;

            ---------------- PULSE OUTPUTS ----------------
            if (i_prev = '0' and i_state = '1') then
                btn_issue_clean <= '1';
            else
                btn_issue_clean <= '0';
            end if;

            if (n_prev = '0' and n_state = '1') then
                btn_next_clean <= '1';
            else
                btn_next_clean <= '0';
            end if;

            if (r_prev = '0' and r_state = '1') then
                btn_reset_clean <= '1';
            else
                btn_reset_clean <= '0';
            end if;

            i_prev <= i_state;
            n_prev <= n_state;
            r_prev <= r_state;

        end if;
    end process;


    ---------------------------------------------------------------------
    -- 3. 00–99 BCD counters (legal VHDL)
    ---------------------------------------------------------------------
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            nt_tens <= (others => '0'); nt_ones <= (others => '0');
            ns_tens <= (others => '0'); ns_ones <= (others => '0');

        elsif rising_edge(clk) then

            -- RESET COUNTERS
            if reset_pulse = '1' then
                nt_tens <= (others => '0'); nt_ones <= (others => '0');
                ns_tens <= (others => '0'); ns_ones <= (others => '0');
            end if;

            -- NEXT TOKEN (00–99)
            if en_next_token = '1' then
                if nt_ones = 9 then
                    nt_ones <= (others => '0');
                    if nt_tens = 9 then
                        nt_tens <= (others => '0');
                    else
                        nt_tens <= nt_tens + 1;
                    end if;
                else
                    nt_ones <= nt_ones + 1;
                end if;
            end if;

            -- NOW SERVING (00–99)
            if en_now_serving = '1' then
                if ns_ones = 9 then
                    ns_ones <= (others => '0');
                    if ns_tens = 9 then
                        ns_tens <= (others => '0');
                    else
                        ns_tens <= ns_tens + 1;
                    end if;
                else
                    ns_ones <= ns_ones + 1;
                end if;
            end if;

        end if;
    end process;


    ---------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------
    next_token_d1  <= std_logic_vector(nt_tens);
    next_token_d0  <= std_logic_vector(nt_ones);
    now_serving_d1 <= std_logic_vector(ns_tens);
    now_serving_d0 <= std_logic_vector(ns_ones);

    next_token_val  <= std_logic_vector(nt_tens) & std_logic_vector(nt_ones);
    now_serving_val <= std_logic_vector(ns_tens) & std_logic_vector(ns_ones);

end architecture;