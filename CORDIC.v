`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 08:58:25 PM
// Design Name: 
// Module Name: CORDIC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CORDIC #(
    parameter iterations = 16
    )(
    input clk,
    input rst,
    input input_ready,
    input [15:0] angle, // signed int from 0-90 in Q8 (256)
    output reg signed output_ready = 'b0,
    output reg signed [15:0] cosine_out = 'd0, // signed int in Q15
    output reg signed [15:0] sine_out =  'd0
    );
    
    // Both expressed in terms of 1/256 of a degree
    reg [15:0] SCALE_FACTOR_LUT [7:0];
    reg [15:0] ANGLE_LUT [15:0]; 
        
        localparam [1:0] START  = 2'b00,
                         CORDIC = 2'b01,
                         MAKE_TABLES = 2'b10;
                     
    reg [1:0] STATE = MAKE_TABLES;  
    reg signed [15:0] calc_angle = 'd0;
    reg [15:0] angle_in = 'd0;
    reg [1:0] rst_sync = 2'b00; // 2 FF syncronizer
    integer loop_num = 'd0;
    
    always @(posedge clk) begin
        if (rst) begin
            rst_sync <= rst_sync + 'd1;
        end else begin
            rst_sync <= 2'b00;
        end

        if (rst_sync[1]) begin
            loop_num <= 'd0;
            output_ready <= 1'b0;
            STATE <= MAKE_TABLES;
        end else begin
            case (STATE)
                // Populate LUT regs
                // Could also be done through a module that reads from a CSV
                MAKE_TABLES: begin
                    ANGLE_LUT[0] <= 16'd11520; // 45 degrees * 256
                    ANGLE_LUT[1] <= 'd6801; // 26.565
                    ANGLE_LUT[2] <= 'd3593;  // 14.036
                    ANGLE_LUT[3] <= 'd1824;  // 7.125
                    ANGLE_LUT[4] <= 'd915;  // 3.576
                    ANGLE_LUT[5] <= 'd458;   // 1.790
                    ANGLE_LUT[6] <= 'd205;   // 0.895
                    ANGLE_LUT[7] <= 'd115;   // 0.448
                    ANGLE_LUT[8] <= 'd57;   // 0.224
                    ANGLE_LUT[9] <= 'd29;    // 0.112
                    ANGLE_LUT[10] <= 'd14;   // 0.056
                    ANGLE_LUT[11] <= 'd7;   // 0.028
                    ANGLE_LUT[12] <= 'd4;    // 0.014
                    ANGLE_LUT[13] <= 'd2;    // 0.007
                    ANGLE_LUT[14] <= 'd1;    // 0.003
                    ANGLE_LUT[15] <= 'd1;
                    
                    SCALE_FACTOR_LUT[0] <= 16'd23170; // cos(45) rounded to nearest 2^15
                    SCALE_FACTOR_LUT[1] <= 16'd20724;
                    SCALE_FACTOR_LUT[2] <= 16'd20105;
                    SCALE_FACTOR_LUT[3] <= 16'd19950;
                    SCALE_FACTOR_LUT[4] <= 16'd19911;
                    SCALE_FACTOR_LUT[5] <= 16'd19901;
                    SCALE_FACTOR_LUT[6] <= 16'd19899;
                    SCALE_FACTOR_LUT[7] <= 16'd19898;
                    
                    STATE <= START;
                end
            
                START: begin
                    if (input_ready) begin
                        if (iterations >= 'd8) begin
                            cosine_out <= SCALE_FACTOR_LUT[7];
                        end else begin
                            cosine_out <= SCALE_FACTOR_LUT[iterations - 1];
                        end
                        
                        loop_num <= 'd0;
                        sine_out <= 'd0;
                        calc_angle <= 'd0;
                        output_ready <= 1'b0;
                        // prevent inputs above 90
                        if (angle < 'd46080) begin
                            angle_in <= angle; 
                        end else begin
                            angle_in <= 'd46080;
                        end
                        STATE <= CORDIC;
                    end
                end
                
                CORDIC: begin
                    if ((loop_num >= iterations) || (loop_num >= 'd16)) begin
                        // multiply output by 64 to scale result to fit full 16 bit output
                        output_ready <= 1'b1;
                        STATE <= START;
                    end else begin
                        // Update cosine, sine, angle
                        if (calc_angle <= angle_in) begin
                            cosine_out <= cosine_out - (sine_out >> loop_num);
                            sine_out <= sine_out + (cosine_out >> loop_num);
                            calc_angle <= calc_angle + ANGLE_LUT[loop_num];
                        end else begin
                            cosine_out <= cosine_out + (sine_out >> loop_num);
                            sine_out <= sine_out - (cosine_out >> loop_num);
                            calc_angle <= calc_angle - ANGLE_LUT[loop_num];
                        end
                    end
                    loop_num <= loop_num + 'd1;
                end
            endcase
        end
    end
endmodule
