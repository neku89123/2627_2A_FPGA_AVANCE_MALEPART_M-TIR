library ieee;
use ieee.std_logic_1164.all;

library nios;

entity tp_nios_v is
    port (
        i_clk           : in    std_logic;
        i_rst_n         : in    std_logic;

        o_led           : out   std_logic_vector(9 downto 0);

        -- ADXL345 (I2C)
        io_i2c_scl      : inout std_logic;
        io_i2c_sda      : inout std_logic;
        o_i2c_ncs       : out   std_logic;
        o_i2c_sdo       : out   std_logic;

        -- HDMI (ecran magique)
        io_hdmi_i2c_scl : inout std_logic;
        io_hdmi_i2c_sda : inout std_logic;
        o_hdmi_tx_clk   : out   std_logic;
        o_hdmi_tx_d     : out   std_logic_vector(23 downto 0);
        o_hdmi_tx_de    : out   std_logic;
        o_hdmi_tx_hs    : out   std_logic;
        i_hdmi_tx_int   : in    std_logic;
        o_hdmi_tx_vs    : out   std_logic;

        -- Encodeurs de la TELECRAN
        i_left_ch_a     : in    std_logic;
        i_left_ch_b     : in    std_logic;
        i_right_ch_a    : in    std_logic;
        i_right_ch_b    : in    std_logic;

        -- LED de la DE10-Nano
        o_de10_leds     : out   std_logic_vector(7 downto 0)
    );
end entity tp_nios_v;

architecture rtl of tp_nios_v is

    signal s_i2c_sda_in : std_logic;
    signal s_i2c_scl_in : std_logic;
    signal s_i2c_sda_oe : std_logic;
    signal s_i2c_scl_oe : std_logic;

    -- pio_1 : bit 0 = effacement de l'ecran magique (actif a '0')
    signal s_pio_1      : std_logic_vector(7 downto 0);

begin

    nios0 : entity nios.nios
        port map (
            clk_clk                          => i_clk,
            reset_reset_n                    => i_rst_n,
            pio_0_external_connection_export => o_led,
            pio_1_external_connection_export => s_pio_1,
            i2c_0_i2c_serial_sda_in          => s_i2c_sda_in,
            i2c_0_i2c_serial_scl_in          => s_i2c_scl_in,
            i2c_0_i2c_serial_sda_oe          => s_i2c_sda_oe,
            i2c_0_i2c_serial_scl_oe          => s_i2c_scl_oe
        );

    -- I2C en drain ouvert : on tire a '0' ou on laisse flotter (pull-up)
    s_i2c_scl_in <= io_i2c_scl;
    io_i2c_scl   <= '0' when s_i2c_scl_oe = '1' else 'Z';

    s_i2c_sda_in <= io_i2c_sda;
    io_i2c_sda   <= '0' when s_i2c_sda_oe = '1' else 'Z';

    -- ADXL345 : nCS = '1' -> mode I2C ; SDO = '0' -> adresse 0x53
    o_i2c_ncs <= '1';
    o_i2c_sdo <= '0';

    -- Ecran magique (projet de mineure)
    telecran0 : entity work.telecran
        port map (
            i_clk_50        => i_clk,
            io_hdmi_i2c_scl => io_hdmi_i2c_scl,
            io_hdmi_i2c_sda => io_hdmi_i2c_sda,
            o_hdmi_tx_clk   => o_hdmi_tx_clk,
            o_hdmi_tx_d     => o_hdmi_tx_d,
            o_hdmi_tx_de    => o_hdmi_tx_de,
            o_hdmi_tx_hs    => o_hdmi_tx_hs,
            i_hdmi_tx_int   => i_hdmi_tx_int,
            o_hdmi_tx_vs    => o_hdmi_tx_vs,
            i_rst_n         => i_rst_n,
            o_de10_leds     => o_de10_leds,
            i_left_ch_a     => i_left_ch_a,
            i_left_ch_b     => i_left_ch_b,
            i_left_pb       => '1',          -- non utilise
            i_right_ch_a    => i_right_ch_a,
            i_right_ch_b    => i_right_ch_b,
            i_right_pb      => '1',          -- non utilise
            i_clear_n       => s_pio_1(0)    -- effacement commande par le Nios V
        );

end architecture rtl;
