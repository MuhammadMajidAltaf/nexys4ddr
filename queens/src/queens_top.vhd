library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity queens_top is

  generic (
            FREQ       : integer := 100000000;
            NUM_QUEENS : integer := 8
          );
  port (
      -- Clock
         clk_i   : in  std_logic;  -- 100 MHz

      -- Input switches
         sw_i        : in  std_logic_vector (7 downto 0);

      -- Output LEDs
         led_o       : out std_logic_vector (7 downto 0);

      -- Output segment display
         seg_ca_o    : out std_logic_vector (6 downto 0);
         seg_dp_o    : out std_logic;
         seg_an_o    : out std_logic_vector (3 downto 0);

      -- pragma synthesis_off
         board_o     : out std_logic_vector (NUM_QUEENS*NUM_QUEENS-1 downto 0);
         num_solutions_o : out std_logic_vector(13 downto 0);
         valid_o     : out std_logic;
         done_o      : out std_logic;
         enable_o    : out std_logic;
      -- pragma synthesis_on

      -- VGA port
         vga_hs_o    : out std_logic; 
         vga_vs_o    : out std_logic;
         vga_red_o   : out std_logic_vector (3 downto 0); 
         vga_green_o : out std_logic_vector (3 downto 0); 
         vga_blue_o  : out std_logic_vector (3 downto 0)
       );

end queens_top;

architecture Structural of queens_top is

  signal queens_en : std_logic;

  signal rst      : std_logic;
  signal vga_clk  : std_logic;

  signal hcount   : std_logic_vector(11 downto 0);
  signal vcount   : std_logic_vector(11 downto 0);
  signal blank    : std_logic;

  signal vga      : std_logic_vector (11 downto 0);

  signal clk_1kHz : std_logic;
  signal seg3     : std_logic_vector (6 downto 0);  -- First segment
  signal seg2     : std_logic_vector (6 downto 0);  -- Second segment
  signal seg1     : std_logic_vector (6 downto 0);  -- Third segment
  signal seg0     : std_logic_vector (6 downto 0);  -- Fourth segment
  signal dp       : std_logic_vector (4 downto 1);

  signal num_solutions : std_logic_vector(13 downto 0);
  signal board    : std_logic_vector(NUM_QUEENS*NUM_QUEENS-1 downto 0);
  signal valid    : std_logic;
  signal done     : std_logic;

begin

    -- Input / output signals
  rst               <= sw_i(0);
  led_o(7 downto 0) <= sw_i(7 downto 0);

  vga_red_o   <= vga(11 downto 8);
  vga_green_o <= vga(7 downto 4);
  vga_blue_o  <= vga(3 downto 0);

    -- pragma synthesis_off
  board_o         <= board         ;
  num_solutions_o <= num_solutions ;
  valid_o         <= valid         ;
  done_o          <= done          ;
  enable_o        <= queens_en     ;
    -- pragma synthesis_on

    -- Generate VGA clock
  inst_clk_wiz_0 : entity work.clk_wiz_0
  port map
  (
    clk_in1 => clk_i,
    clk_out1 => vga_clk
  );

    -- Generate a single pulse for every time the board should be updated.
  inst_counter : entity work.counter
  generic map (
                FREQ    => FREQ       
              )
  port map (
             rst_i   => rst       ,
             clk_i   => vga_clk   ,
             speed_i => sw_i(7 downto 1),
             en_o    => queens_en
           );

    -- This controls the cards
  inst_queens : entity work.queens
  generic map (
                NUM_QUEENS => NUM_QUEENS
              )
  port map ( 
             rst_i    => rst      ,
             clk_i    => vga_clk  ,
             en_i     => queens_en  ,
             board_o  => board      ,
             valid_o  => valid      ,
             done_o   => done   
           );

    -- This generates the image
  inst_disp_queens : entity work.disp_queens
  generic map (
                NUM_QUEENS => NUM_QUEENS
              )
  port map (
             vga_clk_i  => vga_clk  ,
             hcount_i   => hcount   ,
             vcount_i   => vcount   ,
             blank_i    => blank    ,
             board_i    => board    ,
             vga_o      => vga
           );

    -- This generates the VGA timing signals
  inst_vga_ctrl : entity work.vga_ctrl
  port map (
             rst_i     => rst       ,
             vga_clk_i => vga_clk   ,
             HS_o      => vga_hs_o  ,
             VS_o      => vga_vs_o  ,
             hcount_o  => hcount    ,
             vcount_o  => vcount    ,
             blank_o   => blank       
           );

  process (rst, vga_clk) is
  begin
    if rst = '1' then
      num_solutions <= (others => '0');
    elsif rising_edge(vga_clk) then
      if valid = '1' and queens_en = '1' then
        num_solutions <= num_solutions + "00000000000001";
      end if;
    end if;
  end process;

  inst_seg : entity work.seg
  port map ( 
             clk_1kHz_i  => clk_1kHz,
             seg_ca_o    => seg_ca_o,
             seg_dp_o    => seg_dp_o,
             seg_an_o    => seg_an_o,
             seg3_i      => seg3,
             seg2_i      => seg2,
             seg1_i      => seg1,
             seg0_i      => seg0,
             dp_i        => dp
           );

  inst_int2seg : entity work.int2seg
  port map (
             int_i  => num_solutions,
             seg3_o => seg3,
             seg2_o => seg2,
             seg1_o => seg1,
             seg0_o => seg0,
             dp_o   => dp
           );

  inst_clk : entity work.clk
  generic map (
                SCALER => 100000000/1000
              )
  port map (
             clk_i => vga_clk,
             clk_o => clk_1kHz
           );

end Structural;

