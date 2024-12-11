LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;         -- 添加这一行

ENTITY rglight IS
    PORT(clk_0,rst: IN STD_LOGIC;
    button_0:IN STD_LOGIC;
			led: OUT STD_LOGIC_VECTOR(5 DOWNTO  0);	--定义6个LED灯
			main_seg1: OUT STD_LOGIC_VECTOR(6 DOWNTO  0);  --主干倒计时的十位
			main_seg0: OUT STD_LOGIC_VECTOR(6 DOWNTO  0);  --主干倒计时的个位
			f_seg1: OUT STD_LOGIC_VECTOR(6 DOWNTO  0);  --支干倒计时的十位
			f_seg0: OUT STD_LOGIC_VECTOR(6 DOWNTO  0));  --支干倒计时的个位
            
END ENTITY rglight;

ARCHITECTURE bhv OF rglight IS
    TYPE state IS(s0,s1,s2,s3,s4);  --枚举状态类型
    SIGNAL pr_state,nx_state:state;
    SIGNAL count80:STD_LOGIC_VECTOR(7 DOWNTO  0);
    SIGNAL m1_n, m0_n,f1_n, f0_n : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL clk, fast_clk : std_logic;
    
component seg is
        port(
            a: in std_logic_vector(3 downto 0);
            led7s: out std_logic_vector(6 downto 0)
        );
    end component;

component diver is
        port(
            clk: in std_logic;    -- 原始时钟频率
            clk0: out std_logic;  -- 正常计时分频
            clk1: out std_logic   -- 设置闹铃和校时分频
        );
    end component;

BEGIN
    U0: diver port map (clk => clk_0, clk0 => clk, clk1 => fast_clk);
    U1: seg port map (a=>f1_n, led7s => f_seg1);
    U2: seg port map (a=>f0_n, led7s => f_seg0);
    U3: seg port map (a=>m1_n, led7s => main_seg1);
    U4: seg port map (a=>m0_n, led7s => main_seg0);
    PROCESS(rst,clk)                --辅助进程
    BEGIN
    IF (button_0 ='1')THEN
        IF (rst= '0') THEN    --异步清零
        count80<="00000000";
        ELSIF (clk'EVENT AND clk='1') THEN
            IF (count80<"01001111") THEN    
            count80<=count80+1;
            ELSE 
            count80<="00000000"; 
            END IF;
        END IF;
    ELSE
        count80<="00000000";
    END IF;
    END PROCESS;
        
    PROCESS(rst,clk)
    BEGIN
        IF(rst = '0')THEN
            pr_state <= s0;
        ELSIF(clk'EVENT AND clk = '1')THEN
            pr_state <= nx_state;
        END IF;
    END PROCESS;
    
    PROCESS(count80,pr_state,button_0)
    VARIABLE m_seg,f_seg:STD_LOGIC_VECTOR(7 DOWNTO  0);

    BEGIN
        CASE pr_state IS
            WHEN s0 =>
                led<="001100";
                IF(button_0='1')THEN
                nx_state <= s1;
                ELSE
                nx_state <=s0;
                END IF;
                
            WHEN s1 =>
            IF(button_0='1')THEN
                led<="001100";
                --m_seg:=44-count80;
                --f_seg:=49-count80;
                m_seg := std_logic_vector(to_unsigned(45 - to_integer(unsigned(count80)), 8));
                f_seg := std_logic_vector(to_unsigned(50 - to_integer(unsigned(count80)), 8));
                IF count80 = "00101100"THEN
                    nx_state<=s2;
                ELSE
                    nx_state<=s1;
                END IF;
            ELSE
                nx_state <=s0;
            END IF;
                
            WHEN s2 =>
            IF(button_0='1')THEN
                led<="010100";
                --m_seg:=49-count80;
                m_seg := std_logic_vector(to_unsigned(50 - to_integer(unsigned(count80)), 8));
                --f_seg:=49-count80;
                f_seg := std_logic_vector(to_unsigned(50 - to_integer(unsigned(count80)), 8));
                IF count80 = "00110001"THEN
                    nx_state<=s3;
                ELSE
                    nx_state<=s2;
                END IF;
                --数码管显示还没写
            ELSE 
                nx_state <=s0;
            END IF;
                
            WHEN s3 =>
            IF(button_0='1')THEN
                led<="100001";
                --m_seg:=79-count80;
                m_seg := std_logic_vector(to_unsigned(80 - to_integer(unsigned(count80)), 8));

                --f_seg:=74-count80;
                f_seg := std_logic_vector(to_unsigned(75 - to_integer(unsigned(count80)), 8));
                IF count80 = "01001010"THEN
                    nx_state<=s4;
                ELSE
                    nx_state<=s3;
                END IF;
                --数码管显示还没写
            ELSE 
                nx_state <=s0;
            END IF;
            
            WHEN s4 =>
            IF(button_0='1')THEN
                led<="100001";
                --m_seg:=79-count80;
                m_seg := std_logic_vector(to_unsigned(80 - to_integer(unsigned(count80)), 8));
                --f_seg:=79-count80;
                f_seg := std_logic_vector(to_unsigned(80 - to_integer(unsigned(count80)), 8));
                IF count80 = "01001111"THEN
                    nx_state<=s0;
                ELSE
                    nx_state<=s4;
                END IF;
                --数码管显示还没写
            ELSE 
                nx_state <=s0;
            END IF;
        END CASE;
        
        IF m_seg>39 THEN
            m_seg:=m_seg+24;
        ELSIF m_seg>29 THEN 
            m_seg:=m_seg+18;
        ELSIF m_seg>19 THEN
            m_seg:=m_seg+12;
        ELSIF m_seg>9 THEN
            m_seg:=m_seg+6;
        ELSE NULL;
        END IF;
        
        IF f_seg>39 THEN
            f_seg:=f_seg+24;
        ELSIF f_seg>29 THEN 
            f_seg:=f_seg+18;
        ELSIF f_seg>19 THEN 
            f_seg:=f_seg+12;
        ELSIF f_seg>9 THEN 
            f_seg:=f_seg+6;
        ELSE NULL;
        END IF;
        
        IF (rst='0'OR button_0='0')THEN
        m1_n<="0000";
        m0_n<="0000";
        f1_n<="0000";
        f0_n<="0000";
        ELSE
            IF fast_clk='1'THEN
            m1_n<=m_seg(7 DOWNTO 4);
            m0_n<=m_seg(3 DOWNTO 0);
            f1_n<=f_seg(7 DOWNTO 4);
            f0_n<=f_seg(3 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;  

END ARCHITECTURE bhv;

            
                    
                    