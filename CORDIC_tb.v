`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for the CORDIC module
//////////////////////////////////////////////////////////////////////////////////

module tb_CORDIC;

    reg clk = 0;
    reg rst = 0;
    reg input_ready = 0;
    reg [15:0] angle = 0;

    wire output_ready;
    wire [15:0] cosine_out;
    wire [15:0] sine_out;
    
    real angle_real, cosine_real, sine_real;

    // Instantiate the CORDIC module
    CORDIC #(
        .iterations(16)
    ) uut (
        .clk(clk),
        .rst(rst),
        .input_ready(input_ready),
        .angle(angle),
        .output_ready(output_ready),
        .cosine_out(cosine_out),
        .sine_out(sine_out)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock

    initial begin
        $display("Starting CORDIC Test...");
        $display("Time(ns)\tAngle (deg)\tCosine (Q15)\tSine (Q15)");

        // Reset sequence
        //#10;
        //rst = 1;
        //#20;
        //rst = 0;

        #40;

        // Test input: 45 degrees
        angle = 16'd11520;
        input_ready = 1;

        #10;
        input_ready = 0;

        // Wait for output_ready
        wait (output_ready == 1);
        
        cosine_real = $itor(cosine_out) / 32768.0;
        sine_real = $itor(sine_out) / 32768.0;
        angle_real = angle / 256;
        
        $display("%0t\t\t%d\t\t%0.5f\t\t%0.5f", $time, angle_real, cosine_real, sine_real);

        // Next test: 10 degrees
        #10;
        angle = 16'd2560;
        input_ready = 1;
        #10;
        input_ready = 0;

        wait (output_ready == 1);

        cosine_real = $itor(cosine_out) / 32768.0;
        sine_real = $itor(sine_out) / 32768.0;
        angle_real = angle / 256;
        
        $display("%0t\t\t%d\t\t%0.5f\t\t%0.5f", $time, angle_real, cosine_real, sine_real);

        // Next test: 30 degrees
        #10;
        angle = 16'd7680;
        input_ready = 1;
        #10;
        input_ready = 0;

        wait (output_ready == 1);

        cosine_real = $itor(cosine_out) / 32768.0;
        sine_real = $itor(sine_out) / 32768.0;
        angle_real = angle / 256;
        
        $display("%0t\t\t%d\t\t%0.5f\t\t%0.5f", $time, angle_real, cosine_real, sine_real);

        // Done
        #20;
        $finish;
    end

endmodule
