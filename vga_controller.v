`timescale 1ns / 1ps

module vga_controller(
    input clk_100MHz,   // from Basys 3
    input reset,        
    output video_on,    
    output hsync,       
    output vsync,       
    output p_tick,      
    output [9:0] x,     
    output [9:0] y      
);

    // ================= VGA 640x480 Timing =================
    parameter HD = 640;             
    parameter HF = 16;   //front porch           
    parameter HB = 48;   //back porch         
    parameter HR = 96;   //sync pulse           
    parameter HMAX = HD+HF+HB+HR-1; 

    parameter VD = 480;             
    parameter VF = 10;    //front porch          
    parameter VB = 33;    //back porch          
    parameter VR = 2;     //sync pulse          
    parameter VMAX = VD+VF+VB+VR-1; 

    // ================= Generate 25MHz Enable =================
    reg  [1:0] r_25MHz;
    wire w_25MHz;

    always @(posedge clk_100MHz or posedge reset)
    begin
        if(reset)
            r_25MHz <= 0;
        else
            r_25MHz <= r_25MHz + 1;
    end

    assign w_25MHz = (r_25MHz == 0)? 1 : 0;  // 1 clock pulse every 4 cycles
    assign p_tick  = w_25MHz;

    // ================= Horizontal Counter =================
    reg [9:0] h_count_reg;

    always @(posedge clk_100MHz or posedge reset)
    begin
        if(reset)
            h_count_reg <= 0;
        else if(w_25MHz)
        begin
            if(h_count_reg == HMAX)
                h_count_reg <= 0;
            else
                h_count_reg <= h_count_reg + 1;
        end
    end

    // ================= Vertical Counter =================
    reg [9:0] v_count_reg;

    always @(posedge clk_100MHz or posedge reset)
    begin
        if(reset)
            v_count_reg <= 0;
        else if(w_25MHz)
        begin
            if(h_count_reg == HMAX)
            begin
                if(v_count_reg == VMAX)
                    v_count_reg <= 0;
                else
                    v_count_reg <= v_count_reg + 1;
            end
        end
    end

    // ================= Sync Signal Generation =================
    reg h_sync_reg, v_sync_reg;

    wire h_sync_next;
    wire v_sync_next;

    assign h_sync_next = 
        (h_count_reg >= (HD+HB)) && 
        (h_count_reg <= (HD+HB+HR-1));

    assign v_sync_next = 
        (v_count_reg >= (VD+VB)) && 
        (v_count_reg <= (VD+VB+VR-1));

    always @(posedge clk_100MHz or posedge reset)
    begin
        if(reset)
        begin
            h_sync_reg <= 0;
            v_sync_reg <= 0;
        end
        else if(w_25MHz)
        begin
            h_sync_reg <= h_sync_next;
            v_sync_reg <= v_sync_next;
        end
    end

    // ================= Video ON =================
    assign video_on = 
        (h_count_reg < HD) && 
        (v_count_reg < VD);

    // ================= Outputs =================
    assign hsync = h_sync_reg;
    assign vsync = v_sync_reg;
    assign x = h_count_reg;
    assign y = v_count_reg;

endmodule
